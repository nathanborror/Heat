import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
final class ConversationViewModel {
    var store: Store
    var conversationID: String?
    var error: HeatKitError?
    
    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store) {
        self.store = store
        self.conversationID = nil
        self.error = nil
    }
    
    var conversation: Conversation? {
        store.get(conversationID: conversationID)
    }
    
    var messagesVisible: [Message] {
        conversation?.messages.filter { $0.kind != .instruction } ?? []
    }
    
    var title: String {
        conversation?.title ?? Conversation.titlePlaceholder
    }
    
    var suggestions: [String] {
        conversation?.suggestions ?? []
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() {
        guard let agentID = store.preferences.defaultAgentID else { return }
        guard let agent = store.get(agentID: agentID) else { return }
        let conversation = store.createConversation(agent: agent)
        store.upsert(conversation: conversation)
        conversationID = conversation.id
    }
    
    func generate(_ content: String) throws {
        guard !content.isEmpty else { return }
        
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        let toolService = try store.preferredToolService()
        let toolModel = try store.preferredToolModel()
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: .init(role: .user, content: content)) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .generateStream(service: chatService, model: chatModel, tools: conversation.tools) { message in
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                    self.store.replace(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                   self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage { _ in
                    self.store.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .generate(service: toolService, model: toolModel, tool: .generateSuggestions) { message in
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
            throw HeatKitError.missingConversation
        }
        let message = Message(role: .user, content: content, attachments: images.map {
            .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
        })
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: message) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .generateStream(service: visionService, model: visionModel) { message in
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                    self.store.replace(message: message, conversationID: conversation.id)
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
    
    func generateSummary(url: String, markdown: String) throws {
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        let toolService = try store.preferredToolService()
        let toolModel = try store.preferredToolModel()
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: .init(kind: .instruction, role: .user, content: "Summarize:\n\n\(markdown)")) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .append(message: .init(kind: .ignore, role: .user, content: "Summarize: \(url)")) { message in
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
                .generateStream(service: chatService, model: chatModel, tools: conversation.tools) { message in
                    self.store.replace(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                }
                .manage { _ in
                    self.store.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .generate(service: toolService, model: toolModel, tool: .generateSuggestions) { message in
                    let suggestions = self.prepareSuggestions(message)
                    self.store.upsert(suggestions: suggestions, conversationID: conversation.id)
                    self.store.upsert(state: .none, conversationID: conversation.id)
                }
                .manage { manager in
                    guard let error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
        }
    }
    
    func generateImage(_ content: String) throws {
        let imageService = try store.preferredImageService()
        let imageModel = try store.preferredImageModel()
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        generateTask = Task {
            await MediaManager()
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
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: .init(role: .user, content: """
                    Return a title for this conversation if there is a clear subject.
                    Keep the title under 4 words.
                    Return NONE if there is no clear subject.
                    Do not return anything else.
                    """))
                .generate(service: chatService, model: chatModel) { message in
                    guard let title = message.content, !title.isEmpty, title != "NONE" else { return }
                    self.store.upsert(title: title, conversationID: conversation.id)
                }
                .manage { manager in
                    guard let error = manager.error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
        }
    }
    
    func generateStop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        store.upsert(state: .none, conversationID: conversationID)
    }
    
    // MARK: - Private
    
    private func hapticTap(style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
    
    private func prepareSuggestions(_ message: Message) -> [String] {
        guard let toolCalls = message.toolCalls else { return [] }
        guard let toolCall = toolCalls.first(where: { $0.function.name == Tool.generateSuggestions.function.name }) else { return [] }
        do {
            let suggestions = try Tool.GenerateSuggestions.decode(toolCall.function.arguments)
            return Array(suggestions.prompts.prefix(3))
        } catch {
            self.error = HeatKitError.failedSuggestions
        }
        return []
    }
}

