import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
@MainActor
final class ConversationViewModel {
    var conversationID: String? = nil
    var error: Error? = nil
    
    private var generateTask: Task<(), Error>? = nil
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? ConversationProvider.shared.get(conversationID)
    }
    
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesProvider.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentProvider.shared.get(agentID)
        let instructions = agent.instructions.map {
            var message = $0
            message.content = message.content?.apply(context: [
                "datetime": Date.now.format(as: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
            ])
            return message
        }
        let tools = Toolbox.get(tools: agent.toolIDs)
        let conversation = try await ConversationProvider.shared.create(instructions: instructions, tools: tools)
        conversationID = conversation.id
    }
    
    func generate(chat prompt: String, memories: [String] = [], toolChoice: Tool? = nil) throws {
        guard !prompt.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let provider = ConversationProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            
            // Get updated conversation
            let conversation = try provider.get(conversation.id)
            
            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(messages: conversation.messages)
            req.with(tools: conversation.tools)
            req.with(memories: memories)
            
            // Generate response stream
            let stream = ChatSession.shared.stream(req)
            for try await message in stream {
                try await provider.upsert(suggestions: [], conversationID: conversation.id)
                try await provider.upsert(message: message, conversationID: conversation.id)
                try await provider.upsert(state: .processing, conversationID: conversation.id)
            }
            
            // Generate suggestions
            try await generateSuggestions()
            
            // Title conversation
            try await generateTitle()
        }
    }
    
    func generate(chat prompt: String, images: [Data], memories: [String] = []) throws {
        guard !prompt.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let provider = ConversationProvider.shared
        let service = try PreferencesProvider.shared.preferredVisionService()
        let model = try PreferencesProvider.shared.preferredVisionModel()
        
        generateTask = Task {
            // New user message
            let userMessage = Message(role: .user, content: prompt, attachments: images.map {
                .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
            })
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            
            // Get updated conversation
            let conversation = try provider.get(conversation.id)
            
            // Initial request
            var req = VisionSessionRequest(service: service, model: model)
            req.with(messages: conversation.messages)
            req.with(memories: memories)
            
            // Generate response stream
            let stream = VisionSession.shared.stream(req)
            for try await message in stream {
                try await provider.upsert(suggestions: [], conversationID: conversation.id)
                try await provider.upsert(message: message, conversationID: conversation.id)
                try await provider.upsert(state: .processing, conversationID: conversation.id)
            }
            
            // Generate suggestions
            try await generateSuggestions()
            
            // Title conversation
            try await generateTitle()
        }
    }
    
    func generate(image prompt: String) throws {
        guard !prompt.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let provider = ConversationProvider.shared
        let service = try PreferencesProvider.shared.preferredImageService()
        let model = try PreferencesProvider.shared.preferredImageModel()
        
        generateTask = Task {
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            try await provider.upsert(state: .processing, conversationID: conversation.id)
            
            // Generate image
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let data = try await service.imagine(request: req)
            
            // Save images as assistant response
            let attachments = data.map {
                Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: prompt))
            }
            let message = Message(role: .assistant, content: "A generated image using the prompt:\n\(prompt)", attachments: attachments)
            try await provider.upsert(message: message, conversationID: conversation.id)
            try await provider.upsert(state: .none, conversationID: conversation.id)
        }
    }
    
    func generateTitle() async throws {
        guard let conversation else {
            throw KitError.missingConversation
        }
        guard conversation.title == nil else {
            return
        }
        
        let provider = ConversationProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            let conversation = try provider.get(conversation.id)
            
            var req = ChatSessionRequest(service: service, model: model)
            req.with(messages: conversation.messages)
            req.with(tool: Toolbox.generateTitle.tool)
            
            let titleResp = try await ChatSession.shared.completion(req)
            let title = try titleResp.extractTool(name: TitleTool.function.name, type: TitleTool.Arguments.self)
            try await provider.upsert(title: title.title, conversationID: conversation.id)
        }
    }
    
    func generateSuggestions() async throws {
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let provider = ConversationProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            let conversation = try provider.get(conversation.id)
            
            var req = ChatSessionRequest(service: service, model: model)
            req.with(messages: conversation.messages)
            req.with(tool: Toolbox.generateSuggestions.tool)
            
            try await provider.upsert(state: .suggesting, conversationID: conversation.id)
            
            let resp = try await ChatSession.shared.completion(req)
            let suggestions = try resp.extractTool(name: SuggestTool.function.name, type: SuggestTool.Arguments.self)
            try await provider.upsert(suggestions: suggestions.prompts, conversationID: conversation.id)
            try await provider.upsert(state: .none, conversationID: conversation.id)
        }
    }
    
    func stop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        Task { try await ConversationProvider.shared.upsert(state: .none, conversationID: conversationID) }
    }
    
    // MARK: - Private
    
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
    
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: false)
            case .generateMemory:
                let messages = await MemoryTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .generateSuggestions:
                return .init(messages: [], shouldContinue: false)
            case .generateTitle:
                return .init(messages: [], shouldContinue: false)
            case .searchFiles:
                return .init(messages: [], shouldContinue: false)
            case .searchCalendar:
                let messages = await CalendarSearchTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .searchWeb:
                let messages = await WebSearchTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .browseWeb:
                let messages = await WebBrowseTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            }
        } else {
            let toolResponse = Message(
                role: .tool,
                content: "Unknown tool.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Unknown tool"]
            )
            return .init(messages: [toolResponse], shouldContinue: false)
        }
    }
    
    private func hapticTap(style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
}

