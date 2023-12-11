import SwiftUI
import HeatKit

@Observable
final class ConversationViewModel {
    let store: Store
    
    var conversationID: String?

    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store, chatID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
    }
    
    var conversation: Conversation? {
        guard let conversationID = conversationID else { return nil }
        return store.get(conversationID: conversationID)
    }
    
    var model: Model? {
        guard let conversation = conversation else { return nil }
        return store.get(modelID: conversation.modelID)
    }
    
    var messages: [Message] {
        guard let conversation = conversation else { return [] }
        return conversation.messages.filter { $0.kind != .instruction }
    }
    
    var suggestions: [String] {
        conversation?.suggestions ?? []
    }
    
    func change(model: Model) {
        Task {
            guard var conversation = conversation else { return }
            conversation.modelID = model.id
            await store.upsert(conversation: conversation)
        }
    }
    
    func generateResponse(_ text: String) {
        guard let conversationID = conversationID else { return }
        let message = store.createMessage(role: .user, content: text)
        
        generateTask = Task {
            let manager = try await ConversationManager(store: store, conversationID: conversationID)
                .clearSuggestions()
                .append(message)
                .generateStream()
            
            if store.preferences.isSuggesting {
                try await manager
                    .generateSuggestions()
            }
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
}
