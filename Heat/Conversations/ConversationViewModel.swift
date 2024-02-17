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
    
    init(store: Store, conversationID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
        self.error = nil
    }
    
    var conversation: Conversation? {
        store.get(conversationID: conversationID)
    }
    
    var humanVisibleMessages: [Message] {
        conversation?.messages.filter { $0.kind != .instruction } ?? []
    }
    
    var title: String {
        conversation?.title ?? Conversation.titlePlaceholder
    }
    
    private var messages: [Message] {
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
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        Task {
            await MessageManager(messages: messages)
                .append(message: .init(role: .user, content: content)) { message in
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
                .generateStream(service: chatService, model: chatModel) { message in
                    self.store.replace(message: message, conversationID: conversation.id)
                }
                .manage { manager in
                    guard let error = manager.error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    self.store.upsert(message: message, conversationID: conversation.id)
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
        Task {
            await MessageManager(messages: messages)
                .append(message: message) { message in
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
                .generateStream(service: visionService, model: visionModel) { message in
                    self.store.replace(message: message, conversationID: conversation.id)
                }
                .manage { manager in
                    guard let error = manager.error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    self.store.upsert(message: message, conversationID: conversation.id)
                }
            if title == Conversation.titlePlaceholder {
                try generateTitle()
            }
        }
    }
    
    func generateTitle() throws {
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        Task {
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
        logger.warning("generateStop: not implemented")
    }
}

