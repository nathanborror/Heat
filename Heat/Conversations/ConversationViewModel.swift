import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
final class ConversationViewModel {
    var store: Store
    var conversationID: String?
    var error: KitError?
    
    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store) {
        self.store = store
        self.conversationID = nil
        self.error = nil
    }
    
    var conversation: Conversation? {
        store.get(conversationID: conversationID)
    }
    
    var title: String {
        conversation?.title ?? Conversation.titlePlaceholder
    }
    
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    var artifacts: [Artifact] {
        conversation?.artifacts ?? []
    }
    
    var hasToolCalls: Bool {
        return (messages.last?.toolCalls?.count ?? 0) > 0
    }
    
    func newConversation() {
        guard let agentID = store.preferences.defaultAgentID else { return }
        guard let agent = store.get(agentID: agentID) else { return }
        let conversation = store.createConversation(agent: agent)
        store.upsert(conversation: conversation)
        conversationID = conversation.id
    }
    
    func generate(_ content: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !content.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        let toolService = try store.preferredToolService()
        let toolModel = try store.preferredToolModel()
        
        let context = prepareContext(context)
        
        generateTask = Task {
            await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: .init(role: .user, content: content)) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: chatService, model: chatModel, tools: conversation.tools, toolChoice: toolChoice, stream: store.preferences.shouldStream) { message in
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                   self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage { manager in
                    self.store.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        self.store.upsert(message: message, conversationID: conversation.id)
                    }
                }
            
            // Stop generating if there are tool calls waiting
            guard !hasToolCalls else { return }
            
            // Generate suggestions
            await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: Toolbox.generateSuggestions.message)
                .manage { _ in
                    self.store.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .generate(service: toolService, model: toolModel, tool: Toolbox.generateSuggestions.tool) { message in
                    let suggestions = self.prepareSuggestions(message)
                    self.store.upsert(suggestions: suggestions, conversationID: conversation.id)
                    self.store.upsert(state: .none, conversationID: conversation.id)
                }
                .manage { manager in
                    self.store.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        self.store.upsert(message: message, conversationID: conversation.id)
                    }
                }
            
            // Generate a title for the conversation if one doesn't exist
            if title == Conversation.titlePlaceholder {
                try generateTitle()
            }
        }
    }
    
    func generate(_ content: String, images: [Data]) throws {
        guard !content.isEmpty else { return }
        
        let visionService = try store.preferredVisionService()
        let visionModel = try store.preferredVisionModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        let message = Message(role: .user, content: content, attachments: images.map {
            .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
        })
        generateTask = Task {
            await MessageManager()
                .append(messages: messages)
                .append(message: message) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: visionService, model: visionModel) { message in
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                }
                .manage { manager in
                    self.store.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        self.store.upsert(message: message, conversationID: conversation.id)
                    }
                }
            if title == Conversation.titlePlaceholder {
                try generateTitle()
            }
        }
    }
    
    func generateImage(_ content: String) throws {
        let imageService = try store.preferredImageService()
        let imageModel = try store.preferredImageModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        generateTask = Task {
            await ImageSession.shared
                .manage { _ in
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                    self.store.upsert(message: .init(role: .user, content: content), conversationID: conversation.id)
                }
                .generate(service: imageService, model: imageModel, prompt: content) { images in
                    let attachments = images.map {
                        Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: content))
                    }
                    let message = Message(role: .assistant, content: "A generated image using the prompt:\n\(content)", attachments: attachments)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .none, conversationID: conversation.id)
                }
        }
    }
    
    func generateTitle() throws {
        let service = try store.preferredToolService()
        let model = try store.preferredToolModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        generateTask = Task {
            await MessageManager()
                .append(messages: messages)
                .append(message: Toolbox.generateTitle.message)
                .generate(service: service, model: model, tool: Toolbox.generateTitle.tool) { message in
                    guard let title = self.prepareTitle(message) else { return }
                    self.store.upsert(title: title, conversationID: conversation.id)
                }
                .manage { manager in
                    guard let error = manager.error else { return }
                    logger.error("Failed to generate title: \(error)")
                }
        }
    }
    
    func generateStop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        store.upsert(state: .none, conversationID: conversationID)
    }
    
    func processToolCalls(message: Message) throws {
        guard let toolCalls = message.toolCalls else { return }
        guard let conversationID else { return }
        
        // Parallelize tool calls.
        generateTask = Task {
            var messages: [Message] = []
            var artifacts: [Artifact] = []
            
            await withTaskGroup(of: ToolResponse.self) { group in
                for toolCall in toolCalls {
                    group.addTask {
                        do {
                            return try await self.prepareToolResponse(toolCall: toolCall)
                        } catch {
                            logger.error("ProcessToolCalls Error: \(error, privacy: .public)")
                            return .init()
                        }
                    }
                }
                for await resp in group {
                    messages.append(contentsOf: resp.messages)
                    artifacts.append(contentsOf: resp.artifacts)
                }
            }
            store.upsert(messages: messages, conversationID: conversationID)
            store.upsert(artifacts: artifacts, conversationID: conversationID)
        }
    }
    
    // MARK: - Private
    
    private func hapticTap(style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
    
    private func prepareSuggestions(_ message: Message) -> [String] {
        guard let toolCalls = message.toolCalls else { return [] }
        guard let toolCall = toolCalls.first(where: { $0.function.name == Toolbox.generateSuggestions.name }) else { return [] }
        do {
            let args = try SuggestTool.Arguments(toolCall.function.arguments)
            return Array(args.prompts.prefix(3))
        } catch {
            self.error = KitError.failedSuggestions
        }
        return []
    }
    
    private func prepareTitle(_ message: Message) -> String? {
        guard let toolCalls = message.toolCalls else { return nil }
        guard let toolCall = toolCalls.first(where: { $0.function.name == Toolbox.generateTitle.name }) else { return nil }
        do {
            let args = try TitleTool.Arguments(toolCall.function.arguments)
            return args.title
        } catch {
            print(error)
        }
        return nil
    }
    
    private func prepareContext(_ context: [String]) -> Message? {
        guard !context.isEmpty else { return nil }
        
        return Message(role: .system, content: """
            Some things to remember about who the user is. Use these to better relate to the user when responding:
            
            \(context.joined(separator: "\n"))
            """)
    }
    
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolResponse {
        var resp = ToolResponse()
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                resp.messages = await ImageGeneratorTool.handle(toolCall)
                return resp
            case .generateMemory:
                resp.messages = await MemoryTool.handle(toolCall)
                return resp
            case .generateSuggestions:
                return resp
            case .generateTitle:
                return resp
            case .searchFiles:
                return resp
            case .searchCalendar:
                resp.messages = await CalendarSearchTool.handle(toolCall)
                return resp
            case .searchWeb:
                let args = try WebSearchTool.Arguments(toolCall.function.arguments)
                switch args.kind {
                case .website:
                    //let result = try await WebSearchSession.shared.search(query: args.query)
                    //resp.messages = await WebSearchTool.handle(toolCall, response: result)
                    resp.artifacts.append(.init(url: .init(string: "https://www.google.com/search?q=\(args.query)"), title: "Search"))
                    return resp
                case .news:
                    //let result = try await WebSearchSession.shared.searchNews(query: args.query)
                    //resp.messages = await WebSearchTool.handle(toolCall, response: result)
                    resp.artifacts.append(.init(url: .init(string: "https://www.google.com/search?q=\(args.query)&tbm=nws"), title: "News Search"))
                    return resp
                case .image:
                    let result = try await WebSearchSession.shared.searchImages(query: args.query)
                    resp.messages = await WebSearchTool.handle(toolCall, response: result)
                    return resp
                }
            case .browseWeb:
                resp.messages = await WebBrowseTool.handle(toolCall)
                return resp
            }
        } else {
            resp.messages.append(.init(
                role: .tool,
                content: "Unknown tool.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Unknown tool"]
            ))
            return resp
        }
    }
}

struct ToolResponse {
    var messages: [Message] = []
    var artifacts: [Artifact] = []
}
