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
        conversation?.messages.filter { $0.kind == .error } ?? []
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
            logger.warning("missing conversation")
            return
        }
        Task {
            await MessageManager(messages: messages)
                .append(message: .init(role: .user, content: content))
                .sink { messages in
                    store.upsert(messages: messages, conversationID: conversation.id)
                }
                .generateStream(service: chatService, model: chatModel) { messages in
                    store.upsert(messages: messages, conversationID: conversation.id)
                }
                .sinkError { error in
                    guard let error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    store.upsert(message: message, conversationID: conversation.id)
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
            logger.warning("missing conversation")
            return
        }
        Task {
            await MessageManager(messages: messages)
                .append(message: .init(role: .user, content: "Only return a title for this conversation if there's a clear subject. If a clear subject is not present return NONE. Keep it under 4 words."))
                .generateStream(service: chatService, model: chatModel) { messages in
                    guard let title = messages.last?.content else { return }
                    guard !title.isEmpty else { return }
                    guard title != "NONE" else { return }
                    var conversation = conversation
                    conversation.title = title
                    store.upsert(conversation: conversation)
                }
                .sinkError { error in
                    guard let error else { return }
                    let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                    store.upsert(message: message, conversationID: conversation.id)
                }
        }
    }
    
    func generateStop() {
        logger.warning("generateStop: not implemented")
    }
}

