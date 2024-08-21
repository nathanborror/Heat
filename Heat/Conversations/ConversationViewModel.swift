import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
@MainActor
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
        guard let conversationID else { return nil }
        return try? ConversationStore.shared.get(conversationID)
    }
    
    var title: String {
        conversation?.title ?? "New Conversation"
    }
    
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesStore.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentStore.shared.get(agentID)
        let instructions = agent.instructions.map {
            var message = $0
            message.content = message.content?.apply(context: [
                "datetime": Date.now.format(as: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
            ])
            return message
        }
        let tools = store.get(tools: agent.toolIDs)
        let conversation = try await ConversationStore.shared.create(instructions: instructions, tools: tools)
        conversationID = conversation.id
    }
    
    func generate(_ content: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !content.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let chatService = try PreferencesStore.shared.preferredChatService()
        let chatModel = try PreferencesStore.shared.preferredChatModel()
        
        let toolService = try PreferencesStore.shared.preferredToolService()
        let toolModel = try PreferencesStore.shared.preferredToolModel()
        
        let context = prepareContext(context)
        
        generateTask = Task {
            try await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: .init(role: .user, content: content)) { message in
                    try await ConversationStore.shared.upsert(suggestions: [], conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: chatService, model: chatModel, tools: conversation.tools, toolChoice: toolChoice, stream: PreferencesStore.shared.preferences.shouldStream) { message in
                    try await ConversationStore.shared.upsert(state: .streaming, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage { _ in
                    try await ConversationStore.shared.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .append(message: Toolbox.generateSuggestions.message)
                .generate(service: toolService, model: toolModel, tool: Toolbox.generateSuggestions.tool) { message in
                    let suggestions = self.prepareSuggestions(message)
                    try await ConversationStore.shared.upsert(suggestions: suggestions, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(state: .none, conversationID: conversation.id)
                }
                .manage { manager in
                    try await ConversationStore.shared.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    }
                }
            if title == "New Conversation" {
                try generateTitle()
            }
        }
    }
    
    func generate(_ content: String, images: [Data]) throws {
        guard !content.isEmpty else { return }
        
        let visionService = try PreferencesStore.shared.preferredVisionService()
        let visionModel = try PreferencesStore.shared.preferredVisionModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        let message = Message(role: .user, content: content, attachments: images.map {
            .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
        })
        generateTask = Task {
            try await MessageManager()
                .append(messages: messages)
                .append(message: message) { message in
                    try await ConversationStore.shared.upsert(suggestions: [], conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: visionService, model: visionModel) { message in
                    try await ConversationStore.shared.upsert(state: .streaming, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                }
                .manage { manager in
                    try await ConversationStore.shared.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    }
                }
            if title == "New Conversation" {
                try generateTitle()
            }
        }
    }
    
    func generateImage(_ content: String) throws {
        let imageService = try PreferencesStore.shared.preferredImageService()
        let imageModel = try PreferencesStore.shared.preferredImageModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        generateTask = Task {
            try await ImageSession.shared
                .manage { _ in
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: .init(role: .user, content: content), conversationID: conversation.id)
                }
                .generate(service: imageService, model: imageModel, prompt: content) { images in
                    let attachments = images.map {
                        Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: content))
                    }
                    let message = Message(role: .assistant, content: "A generated image using the prompt:\n\(content)", attachments: attachments)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(state: .none, conversationID: conversation.id)
                }
        }
    }
    
    func generateTitle() throws {
        let service = try PreferencesStore.shared.preferredToolService()
        let model = try PreferencesStore.shared.preferredToolModel()
        
        guard let conversation else {
            throw KitError.missingConversation
        }
        generateTask = Task {
            try await MessageManager()
                .append(messages: messages)
                .append(message: Toolbox.generateTitle.message)
                .generate(service: service, model: model, tool: Toolbox.generateTitle.tool) { message in
                    guard let title = self.prepareTitle(message) else { return }
                    try await ConversationStore.shared.upsert(title: title, conversationID: conversation.id)
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
        Task { try await ConversationStore.shared.upsert(state: .none, conversationID: conversationID) }
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
}

