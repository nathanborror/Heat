import SwiftUI
import OSLog
import HeatKit
import GenKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

@Observable
final class ConversationViewModel {
    let store: Store
    
    var conversationID: String?

    init(store: Store, chatID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
    }
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return store.get(conversationID: conversationID)
    }
    
    var title: String {
        conversation?.title ?? "Choose Conversation"
    }
    
    var messages: [Message] {
        guard let conversation else { return [] }
        return conversation.messages.filter { $0.kind != .instruction }
    }
    
    func generateResponse(content: String? = nil) throws {
        guard let conversation else { return }
        
        guard let chatService = store.preferredChatService() else {
            throw ConversationViewModelError.missingService
        }
        guard let chatModel = store.preferredChatModel() else {
            throw ConversationViewModelError.missingModel
        }
        
        generateTask = Task {
            await MessageManager(messages: conversation.messages)
                .append(message: .init(role: .user, content: content))
                .sink {
                    store.upsert(messages: $0, conversationID: conversation.id)
                }
                .generateStream(service: chatService, model: chatModel) {
                    store.upsert(messages: $0, conversationID: conversation.id)
                }
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
    
    private var generateTask: Task<(), Error>? = nil
}

enum ConversationViewModelError: LocalizedError {
    case missingService
    case missingModel
    
    var errorDescription: String? {
        switch self {
        case .missingService: "Missing service"
        case .missingModel: "Missing model"
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .missingService: "Open Preferences and configure a service."
        case .missingModel: "Open Preferences and pick a preferred model for the service you are using."
        }
    }
}
