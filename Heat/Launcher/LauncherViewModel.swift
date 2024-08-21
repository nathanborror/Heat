import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "LauncherViewModel", category: "Heat")

@Observable
@MainActor
final class LauncherViewModel {
    var store: Store
    var conversationID: String?
    var error: KitError?
    
    private var generateTask: Task<(), Error>? = nil
    
    init(store: Store) {
        self.store = store
        self.conversationID = nil
        self.error = nil
    }
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? ConversationStore.shared.get(conversationID)
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesStore.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentStore.shared.get(agentID)
        let instructions = agent.instructions.map {
            var message = $0
            message.content = message.content?.apply(context: [
                "datetime": Date.now.format(as: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
            ])
            return message
        }
        let tools = store.get(tools: agent.toolIDs)
        let conversation = try await ConversationStore.shared.create(instructions: instructions, tools: tools)
        conversationID = conversation.id
    }
    
    func generate(_ content: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !content.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let chatService = try PreferencesStore.shared.preferredChatService()
        let chatModel = try PreferencesStore.shared.preferredChatModel()
        
        let context = prepareContext(context)
        
        generateTask = Task {
            try await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: .init(role: .user, content: content)) { message in
                    try await ConversationStore.shared.upsert(suggestions: [], conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: chatService, model: chatModel, tools: conversation.tools, toolChoice: toolChoice, stream: PreferencesStore.shared.preferences.shouldStream) { message in
                    try await ConversationStore.shared.upsert(state: .streaming, conversationID: conversation.id)
                    try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                    try await ConversationStore.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage { _ in
                    try await ConversationStore.shared.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .append(message: Toolbox.generateSuggestions.message)
                .manage { manager in
                    try await ConversationStore.shared.upsert(state: .none, conversationID: conversation.id)
                    if let error = manager.error {
                        let message = Message(kind: .error, role: .system, content: error.localizedDescription)
                        try await ConversationStore.shared.upsert(message: message, conversationID: conversation.id)
                    }
                }
        }
    }
    
    func generateStop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        Task { try await ConversationStore.shared.upsert(state: .none, conversationID: conversationID) }
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

