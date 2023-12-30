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
    
    var model: Model? {
        guard let conversation else { return nil }
        return store.get(modelID: conversation.modelID)
    }
    
    var messages: [Message] {
        guard let conversation else { return [] }
        return conversation.messages.filter { $0.kind != .instruction }
    }
    
    func change(model: Model) {
        guard var conversation else { return }
        conversation.modelID = model.id
        store.upsert(conversation: conversation)
    }
    
    func generateResponse(content: String) {
        guard let conversationID else { return }
        guard let url = store.preferences.host else {
            logger.warning("missing ollama host url")
            return
        }
        guard let model else { return }
        let message = Message(role: .user, content: content)
        
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: message)
                .sink { store.upsert(messages: $0, conversationID: conversationID) }
                .generateStream(service: OllamaService(url: url), model: model.name) { messages in
                    store.upsert(messages: messages, conversationID: conversationID)
                }
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
    
    private var generateTask: Task<(), Error>? = nil
}
