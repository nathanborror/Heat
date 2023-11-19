import SwiftUI
import HeatKit

@Observable
final class ChatViewModel {
    let store: Store
    
    var chatID: String?

    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store, chatID: String? = nil) {
        self.store = store
        self.chatID = chatID
    }
    
    var agent: Agent? {
        guard let chatID = chatID else { return nil }
        guard let chat = store.get(chatID: chatID) else { return nil }
        return store.get(agentID: chat.agentID)
    }
    
    var chat: AgentChat? {
        guard let chatID = chatID else { return nil }
        return store.get(chatID: chatID)
    }
    
    var model: Model? {
        guard let chat = chat else { return nil }
        return store.get(modelID: chat.modelID)
    }
    
    var messages: [Message] {
        guard let chat = chat else { return [] }
        return chat.messages.filter { $0.kind != .instruction }
    }
    
    func change(model: Model) {
        Task {
            guard var chat = chat else { return }
            chat.modelID = model.id
            await store.upsert(chat: chat)
        }
    }
    
    func generateResponse(_ text: String) {
        guard let chat = chat else { return }
        let message = store.createMessage(role: .user, content: text)
        
        generateTask = Task {
            try await ChatManager(store: store, chat: chat)
                .clearSuggestions()
                .append(message)
                .generateStream()
                .generateSuggestions()
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
}
