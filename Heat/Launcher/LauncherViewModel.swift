import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "LauncherViewModel", category: "Heat")

@Observable
final class LauncherViewModel {
    var store: Store
    var conversationID: String?
    var error: HeatKitError?
    
    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store) {
        self.store = store
        self.conversationID = nil
        self.error = nil
    }
    
    var conversation: Conversation? {
        store.get(conversationID: conversationID)
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() {
        guard let agentID = store.preferences.defaultAgentID else { return }
        guard let agent = store.get(agentID: agentID) else { return }
        let conversation = store.createConversation(agent: agent)
        store.upsert(conversation: conversation)
        conversationID = conversation.id
    }
    
    func generate(_ content: String, context: [String] = []) throws {
        guard !content.isEmpty else { return }
        guard let conversation else {
            throw HeatKitError.missingConversation
        }
        
        let chatService = try store.preferredChatService()
        let chatModel = try store.preferredChatModel()
        
        let context = prepareContext(context)
        
        generateTask = Task {
            await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: .init(role: .user, content: content)) { message in
                    self.store.upsert(suggestions: [], conversationID: conversation.id)
                    self.store.upsert(message: message, conversationID: conversation.id)
                    self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: chatService, model: chatModel, tools: conversation.tools, stream: store.preferences.shouldStream) { message in
                    self.store.upsert(state: .streaming, conversationID: conversation.id)
                    self.store.replace(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                   self.store.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage { _ in
                    self.store.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .manage { manager in
                    self.store.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        self.store.upsert(message: message, conversationID: conversation.id)
                    }
                }
        }
    }
    
    func generateStop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        store.upsert(state: .none, conversationID: conversationID)
    }
    
    // MARK: - Private
    
    private func hapticTap(style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
    
    private func prepareContext(_ context: [String]) -> Message? {
        guard !context.isEmpty else { return nil }
        
        return Message(role: .system, content: """
            Some things to remember about who the user is. Use these to better relate to the user when responding:
            
            \(context.joined(separator: "\n"))
            """)
    }
}

