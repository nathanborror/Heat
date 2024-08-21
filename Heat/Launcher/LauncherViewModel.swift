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
        return try? ConversationProvider.shared.get(conversationID)
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesProvider.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentProvider.shared.get(agentID)
        let instructions = agent.instructions.map {
            var message = $0
            message.content = message.content?.apply(context: [
                "datetime": Date.now.format(as: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
            ])
            return message
        }
        let tools = store.get(tools: agent.toolIDs)
        let conversation = try await ConversationProvider.shared.create(instructions: instructions, tools: tools)
        conversationID = conversation.id
    }
    
    func generate(_ content: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !content.isEmpty else { return }
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let chatService = try PreferencesProvider.shared.preferredChatService()
        let chatModel = try PreferencesProvider.shared.preferredChatModel()
        
        let context = prepareContext(context)
        
        generateTask = Task {
            try await MessageManager()
                .append(messages: messages)
                .append(message: context)
                .append(message: .init(role: .user, content: content)) { message in
                    try await ConversationProvider.shared.upsert(suggestions: [], conversationID: conversation.id)
                    try await ConversationProvider.shared.upsert(message: message, conversationID: conversation.id)
                    try await ConversationProvider.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .generate(service: chatService, model: chatModel, tools: conversation.tools, toolChoice: toolChoice, stream: PreferencesProvider.shared.preferences.shouldStream) { message in
                    try await ConversationProvider.shared.upsert(state: .streaming, conversationID: conversation.id)
                    try await ConversationProvider.shared.upsert(message: message, conversationID: conversation.id)
                    self.hapticTap(style: .light)
                } processing: {
                    try await ConversationProvider.shared.upsert(state: .processing, conversationID: conversation.id)
                }
                .manage {
                    try await ConversationProvider.shared.upsert(state: .suggesting, conversationID: conversation.id)
                }
                .append(message: Toolbox.generateSuggestions.message)
                .manage {
                    try await ConversationProvider.shared.upsert(state: .none, conversationID: conversation.id)
                }
        }
    }
    
    func generateStop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        Task { try await ConversationProvider.shared.upsert(state: .none, conversationID: conversationID) }
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

