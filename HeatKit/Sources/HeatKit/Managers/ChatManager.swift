import Foundation
import OllamaKit
import OSLog

private let logger = Logger(subsystem: "ChatManager", category: "HeatKit")

enum ConversationManagerError: Error {
    case missingConversation
    case missingResponseMessage
}

public final class ConversationManager {
    let store: Store
    
    var conversationID: String?
    
    private var task: Task<(), Error>? = nil
    
    public init(store: Store, conversationID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
    }
    
    @discardableResult public func initialize(agentID: String? = nil, callback: ((String) -> Void)? = nil) async throws -> Self {
        let conversation = try store.createConversation(agentID: agentID)
        await store.upsert(conversation: conversation)
        conversationID = conversation.id
        callback?(conversation.id)
        return self
    }
    
    @discardableResult public func append(_ message: Message) async throws -> Self {
        try Task.checkCancellation()
        guard let conversationID = conversationID else { throw ConversationManagerError.missingConversation }
        
        await store.upsert(message: message, conversationID: conversationID)
        return self
    }
    
    @discardableResult public func generate() async throws -> Self {
        try Task.checkCancellation()
        guard let conversationID = conversationID else { throw ConversationManagerError.missingConversation }
        
        guard let conversation = store.get(conversationID: conversationID) else { return self }
        guard let model = store.get(modelID: conversation.modelID) else { return self }
        
        await store.set(state: .processing, conversationID: conversationID)
        
        let resp = try await store.chat(model: model, messages: conversation.messages)
        
        guard let message = decode(response: resp) else {
            throw ConversationManagerError.missingResponseMessage
        }
        
        await store.set(state: .none, conversationID: conversationID)
        await store.upsert(message: message, conversationID: conversationID)
        
        return self
    }
    
    @discardableResult public func generateStream() async throws -> Self {
        try Task.checkCancellation()
        guard let conversationID = conversationID else { throw ConversationManagerError.missingConversation }
        
        guard let conversation = store.get(conversationID: conversationID) else { return self }
        guard let model = store.get(modelID: conversation.modelID) else { return self }
        let messageID = UUID().uuidString
        
        await store.set(state: .processing, conversationID: conversationID)
        
        try await store.chatStream(model: model, messages: conversation.messages) { resp in
            guard var message = decode(response: resp) else {
                throw ConversationManagerError.missingResponseMessage
            }
            message.id = messageID
            message.done = resp.done ?? message.done
            await store.upsert(message: message, conversationID: conversationID)
        }
        
        await store.set(state: .none, conversationID: conversationID)
        
        return self
    }
    
    @discardableResult public func generateSuggestions() async throws -> Self {
        try Task.checkCancellation()
        guard let conversationID = conversationID else { throw ConversationManagerError.missingConversation }
        
        guard var conversation = store.get(conversationID: conversationID) else { return self }
        guard let model = store.get(modelID: conversation.modelID) else { return self }
        
        conversation.state = .suggesting
        await store.upsert(conversation: conversation)
        
        let prompt = """
            Generate three suggested user replies in under 8 words each. \
            Respond with a JSON array of strings.
            """
        var messages = conversation.messages
        messages.append(.init(role: .user, content: prompt))
        
        let resp = try await store.chat(model: model, messages: messages)
        
        let cleaned = cleanSuggestions(response: resp)
        if let data = cleaned.data(using: .utf8), var conversation = store.get(conversationID: conversationID) {
            do {
                let suggestions = try JSONDecoder().decode([String].self, from: data)
                conversation.suggestions = suggestions
            } catch {
                logger.error("""
                    Suggestions Failed:
                    - Response: \(resp.message?.content ?? "")
                    - Error: \(error, privacy: .public)
                    """
                )
            }
            conversation.state = .none
            await store.upsert(conversation: conversation)
        }
        return self
    }
    
    @discardableResult public func clearSuggestions() async throws -> Self {
        guard let conversationID = conversationID else { throw ConversationManagerError.missingConversation }
        guard var conversation = store.get(conversationID: conversationID) else { return self }
        conversation.suggestions = nil
        await store.upsert(conversation: conversation)
        return self
    }
}

extension ConversationManager {
    
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
            return .init(role: .assistant)
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
