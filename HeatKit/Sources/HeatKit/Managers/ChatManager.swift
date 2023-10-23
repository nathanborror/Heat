import Foundation

public final class ChatManager {
    let store: Store
    let chatID: String
    
    private var task: Task<(), Error>? = nil
    
    public init(store: Store, chat: AgentChat) {
        self.store = store
        self.chatID = chat.id
    }
    
    @discardableResult public func inject(message: Message) async -> Self {
        guard let chat = store.get(chatID: chatID) else { return self }
        
        // Override model if the chat prefers another model.
        var message = message
        message.model = chat.preferredModel ?? message.model
        
        await store.upsert(message: message, chatID: chatID)
        return self
    }
    
    @discardableResult public func generate() async throws -> Self {
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let message = chat.messages.last else { return self }
        guard message.role == .user else { return self }
        
        await store.set(state: .processing, chatID: chatID)
        
        let resp = try await store.generate(model: message.model, prompt: message.content, system: chat.system, context: chat.context)
        let newAssistantMessage = Message(model: message.model, role: .assistant, content: resp.response, done: resp.done)
        
        await store.set(state: .none, chatID: chatID)
        await store.upsert(message: newAssistantMessage, chatID: chatID)
        await store.set(context: resp.context, chatID: chatID)
        
        return self
    }
    
    @discardableResult public func generateStream() async throws -> Self {
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let message = chat.messages.last else { return self }
        guard message.role == .user else { return self }
        
        await store.set(state: .processing, chatID: chatID)
        
        let newAssistantMessageID = UUID().uuidString
        
        try await store.generateStream(model: message.model, prompt: message.content, system: chat.system, context: chat.context) { resp in
            let newAssistantMessage = Message(id: newAssistantMessageID, model: message.model, role: .assistant, content: resp.response, done: resp.done)
            
            await store.set(state: .streaming, chatID: chatID)
            await store.upsert(message: newAssistantMessage, chatID: chatID)
            
            if resp.done {
                await store.set(context: resp.context, chatID: chatID)
                await store.set(state: .none, chatID: chatID)
            }
        }
        return self
    }
}
