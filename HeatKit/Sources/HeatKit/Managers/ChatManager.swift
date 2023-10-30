import Foundation

public final class ChatManager {
    let store: Store
    let chatID: String
    
    private var task: Task<(), Error>? = nil
    
    public init(store: Store, chat: AgentChat) {
        self.store = store
        self.chatID = chat.id
    }
    
    @discardableResult public func inject(message: Message) async throws -> Self {
        try Task.checkCancellation()
        
        await store.upsert(message: message, chatID: chatID)
        return self
    }
    
    @discardableResult public func generate() async throws -> Self {
        try Task.checkCancellation()
        
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        guard let message = chat.messages.last else { return self }
        guard message.role == .user else { return self }
        
        await store.set(state: .processing, chatID: chatID)
        
        let resp = try await store.generate(model: model, prompt: message.content, system: chat.system, context: chat.context)
        let newAssistantMessage = Message(role: .assistant, content: resp.response, done: resp.done)
        
        await store.set(state: .none, chatID: chatID)
        await store.upsert(message: newAssistantMessage, chatID: chatID)
        await store.set(context: resp.context, chatID: chatID)
        
        return self
    }
    
    @discardableResult public func generateStream() async throws -> Self {
        try Task.checkCancellation()
        
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        guard let message = chat.messages.last else { return self }
        guard message.role == .user else { return self }
        
        await store.set(state: .processing, chatID: chatID)
        
        let newAssistantMessageID = UUID().uuidString
        
        try await store.generateStream(model: model, prompt: message.content, system: chat.system, context: chat.context) { resp in
            let newAssistantMessage = Message(id: newAssistantMessageID, role: .assistant, content: resp.response, done: resp.done)
            
            await store.set(state: .streaming, chatID: chatID)
            await store.upsert(message: newAssistantMessage, chatID: chatID)
            
            if resp.done {
                await store.set(context: resp.context, chatID: chatID)
                await store.set(state: .none, chatID: chatID)
            }
        }
        return self
    }
    
    @discardableResult public func suggestions() async throws -> Self {
        try Task.checkCancellation()
        
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        guard let message = chat.messages.last else { return self }
        guard message.role == .assistant else { return self }
        
        // System Suggestions Agent
        let agent = Agent.systemSuggestions
        
        let prompt =
            """
            You are a helpful code assistant. 
            Generate a valid JSON array of 3 strings.
            The strings are brief suggested responses the USER could make to YOU.
            ONLY generate the JSON array.
            """
        
        await store.set(state: .processing, chatID: chatID)
        
        let resp = try await store.generate(model: model, prompt: prompt, system: chat.system, context: chat.context)
        let newAssistantMessage = Message(role: .assistant, content: resp.response, done: resp.done)
        
        await store.set(state: .none, chatID: chatID)
        await store.upsert(message: newAssistantMessage, chatID: chatID)
        await store.set(context: resp.context, chatID: chatID)
        
        return self
    }
}
