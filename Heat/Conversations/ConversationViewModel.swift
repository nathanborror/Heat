import GenKit
import HeatKit
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "ConversationViewModel", category: "App")

@MainActor @Observable
final class ConversationViewModel {
    var conversationID: Conversation.ID? = nil
    var streamingTokens: String? = nil
    var error: Error? = nil

    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared

    private var generateTask: Task<(), Error>? = nil

    init(conversationID: Conversation.ID) {
        self.conversationID = conversationID
    }

    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? conversationsProvider.get(conversationID)
    }

    /// Suggested replies the user can use to respond.
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }

    /// The instructions (system prompt) that's sent with every request.'
    var instructions: [Message] {
        guard let conversation else { return [] }
        let instructions = Message(role: .system, content: conversation.instructions)
        return [instructions]
    }

    /// The whole conversation history.
    var messages: [Message] {
        guard let conversationID else { return [] }
        let history = try? messagesProvider.get(parentID: conversationID.rawValue)
        return history ?? []
    }

    /// The conversation history aggregated by Run which packages up all tool calls and responses into a Run.
    var runs: [Run] {
        guard conversationID != nil else { return [] }
        return prepareRuns()
    }

    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    func generate(
        chat prompt: String, context: [String: String] = [:], toolChoice: Tool? = nil,
        agentID: Agent.ID? = nil
    ) throws {
        guard let conversationID else { return }
        generateTask = try API.shared.generate(
            conversationID: conversationID, prompt: prompt, context: context,
            toolChoice: toolChoice, agentID: agentID)
    }

    /// Generate a response using images as inputs alongside text. This will eventually be combined with generate(chat: ...) above.
    func generate(chat prompt: String, images: [Data], context: [String: String] = [:]) throws {
        guard let conversationID else { return }
        generateTask = try API.shared.generate(
            conversationID: conversationID, prompt: prompt, images: images, context: context)
    }

    /// Generate an image from a given prompt. This is an explicit way to generate an image, most happen through tool use.
    func generate(image prompt: String) throws {
        guard let conversationID else { return }
        generateTask = try API.shared.generate(conversationID: conversationID, image: prompt)
    }

    /// Cancel any of the generate tasks above.
    func cancel() {
        generateTask?.cancel()
        streamingTokens = nil
        Task {
            guard let conversationID else { return }
            try await conversationsProvider.upsert(state: .none, conversationID: conversationID)
        }
    }

    // MARK: - Private

    /// Bundle messages into runs.
    private func prepareRuns() -> [Run] {
        var runs: [Run] = []
        var currentRun = Run()

        // Cluster message runs
        for message in messages {
            if currentRun.id == message.runID {
                currentRun.messages.append(message)
                currentRun.ended = message.modified
            } else {
                if !currentRun.messages.isEmpty {
                    runs.append(currentRun)
                }
                currentRun = Run(
                    id: message.runID ?? Run.ID(message.id.rawValue),
                    messages: [message],
                    started: message.created,
                    ended: message.modified
                )
            }
        }

        // Append remaining run
        if !currentRun.messages.isEmpty {
            runs.append(currentRun)
        }

        return runs
    }

    /// Execute a haptic tap.
    private func haptic(tap style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
}
