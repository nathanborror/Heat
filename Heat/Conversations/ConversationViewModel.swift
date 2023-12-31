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
    
    var messages: [Message] {
        guard let conversation else { return [] }
        return conversation.messages.filter { $0.kind != .instruction }
    }
    
    func generateResponse(content: String? = nil) {
        guard let conversation else { return }
        guard let model = store.preferences.model else { return }
        
        generateTask = Task {
            await MessageManager(messages: conversation.messages)
                .append(message: .init(role: .user, content: content))
                .sink {
                    store.upsert(messages: $0, conversationID: conversation.id)
                }
                .generateStream(service: try chatService(), model: model) {
                    store.upsert(messages: $0, conversationID: conversation.id)
                }
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
    
    private func chatService() throws -> ChatService {
        switch store.preferences.service {
        case .openai:
            guard let token = store.preferences.token else {
                throw AppError.missingToken
            }
            return OpenAIService(token: token)
        case .ollama:
            guard let host = store.preferences.host else {
                throw AppError.missingHost
            }
            return OllamaService(url: host)
        }
    }
    
    private var generateTask: Task<(), Error>? = nil
}
