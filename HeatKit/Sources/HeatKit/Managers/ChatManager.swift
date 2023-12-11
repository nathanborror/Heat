import Foundation
import OllamaKit
import OSLog

private let logger = Logger(subsystem: "ChatManager", category: "HeatKit")

public final class ChatManager {
    let store: Store
    let chatID: String
    
    private var task: Task<(), Error>? = nil
    
    public init(store: Store, chat: AgentChat) {
        self.store = store
        self.chatID = chat.id
    }
    
    @discardableResult public func append(_ message: Message) async throws -> Self {
        try Task.checkCancellation()
        
        await store.upsert(message: message, chatID: chatID)
        return self
    }
    
    @discardableResult public func generate() async throws -> Self {
        try Task.checkCancellation()
        
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        
        await store.set(state: .processing, chatID: chatID)
        
        let resp = try await store.chat(model: model, messages: chat.messages)
        
        guard let message = decode(response: resp) else {
            logger.error("missing response message")
            return self
        }
        
        await store.set(state: .none, chatID: chatID)
        await store.upsert(message: message, chatID: chatID)
        
        return self
    }
    
    @discardableResult public func generateStream() async throws -> Self {
        try Task.checkCancellation()
        
        guard let chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        let messageID = UUID().uuidString
        
        await store.set(state: .processing, chatID: chatID)
        
        try await store.chatStream(model: model, messages: chat.messages) { resp in
            guard var message = decode(response: resp) else {
                logger.error("missing response message")
                return
            }
            message.id = messageID
            message.done = resp.done ?? message.done
            await store.upsert(message: message, chatID: chat.id)
        }
        
        await store.set(state: .none, chatID: chat.id)
        
        return self
    }
    
    @discardableResult public func generateSuggestions() async throws -> Self {
        try Task.checkCancellation()
        
        guard var chat = store.get(chatID: chatID) else { return self }
        guard let model = store.get(modelID: chat.modelID) else { return self }
        
        chat.state = .suggesting
        await store.upsert(chat: chat)
        
        let prompt = """
            Generate three suggested user replies in under 8 words each. \
            Respond with a JSON array of strings.
            """
        var messages = chat.messages
        messages.append(.init(role: .user, content: prompt))
        
        let resp = try await store.chat(model: model, messages: messages)
        
        let cleaned = cleanSuggestions(response: resp)
        if let data = cleaned.data(using: .utf8), var chat = store.get(chatID: chat.id) {
            do {
                let suggestions = try JSONDecoder().decode([String].self, from: data)
                chat.suggestions = suggestions
            } catch {
                logger.error("""
                    Suggestions Failed:
                    - Response: \(resp.message?.content ?? "")
                    - Error: \(error, privacy: .public)
                    """
                )
            }
            chat.state = .none
            await store.upsert(chat: chat)
        }
        return self
    }
    
    @discardableResult public func clearSuggestions() async throws -> Self {
        guard var chat = store.get(chatID: chatID) else { return self }
        chat.suggestions = nil
        await store.upsert(chat: chat)
        return self
    }
}

extension ChatManager {
    
    private func cleanSuggestions(response: ChatResponse) -> String {
        guard var content = response.message?.content else { return "" }
        if content.hasPrefix("```json") {
            content.removeFirst("```json".count)
        }
        if content.hasSuffix("```") {
            content.removeLast("```".count)
        }
        return content
    }
    
    private func decode(response: ChatResponse) -> Message? {
        guard let message = response.message else {
            return .init(role: .assistant, content: "")
        }
        return .init(role: decode(role: message.role), content: message.content)
    }
    
    private func decode(role: OllamaKit.Message.Role) -> Message.Role {
        switch role {
        case .system: .system
        case .assistant: .assistant
        case .user: .user
        }
    }
}
