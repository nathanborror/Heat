import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
final class ConversationViewModel {
    var store: Store
    var conversationID: String?
    
    init(store: Store, conversationID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
    }
    
    var conversation: Conversation? {
        store.get(conversationID: conversationID)
    }
    
    var humanVisibleMessages: [Message] {
        conversation?.messages.filter { $0.kind != .instruction } ?? []
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    var title: String {
        conversation?.title ?? Conversation.titlePlaceholder
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
        
        guard let conversation else {
            throw ConversationViewModelError.missingConversation
        }
        guard let chatService = store.preferredChatService() else {
            throw ConversationViewModelError.missingService
        }
        guard let chatModel = store.preferredChatModel() else {
            throw ConversationViewModelError.missingModel
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
            
            if title == Conversation.titlePlaceholder {
                try generateTitle()
            }
        }
    }
    
    func generateTitle() throws {
        guard let conversation else {
            throw ConversationViewModelError.missingConversation
        }
        guard let chatService = store.preferredChatService() else {
            throw ConversationViewModelError.missingService
        }
        guard let chatModel = store.preferredChatModel() else {
            throw ConversationViewModelError.missingModel
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
        }
    }
    
    func generateStop() {
        logger.warning("generateStop: not implemented")
    }
}

enum ConversationViewModelError: LocalizedError {
    case missingService
    case missingModel
    case missingConversation
    
    var errorDescription: String? {
        switch self {
        case .missingService: "Missing service"
        case .missingModel: "Missing model"
        case .missingConversation: "Missing conversation"
        }
    }
    
    var failureReason: String? {
        "Failure reason"
    }
    
    var helpAnchor: String? {
        "Halp!"
    }
    
    var recoverySuggestion: String {
        switch self {
        case .missingService: "Open Preferences and configure a service."
        case .missingModel: "Open Preferences and pick a preferred model for the service you are using."
        case .missingConversation: "Not sure how to recover from this."
        }
    }
}
