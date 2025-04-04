import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "App")

@MainActor @Observable
final class ConversationViewModel {
    var conversationID: String? = nil

    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared

    private var generateTask: Task<(), Swift.Error>? = nil

    enum Error: Swift.Error, CustomStringConvertible {
        case missingConversation
        case generationError(String)
        case unexpectedError(String)

        public var description: String {
            switch self {
            case .missingConversation:
                "Missing conversation"
            case .generationError(let detail):
                "Generation error: \(detail)"
            case .unexpectedError(let detail):
                "Unexpected error: \(detail)"
            }
        }
    }

    init(conversationID: String? = nil) {
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
        let history = try? messagesProvider.get(referenceID: conversationID)
        return history ?? []
    }

    /// The conversation history aggregated by Run which packages up all tool calls and responses into a Run.
    var runs: [Run] {
        guard conversationID != nil else { return [] }
        return prepareRuns()
    }

    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    func generate(chat prompt: String, images: [Data] = [], context: [String: Value] = [:], toolChoice: Tool? = nil, agentID: String? = nil) async throws {
        guard let conversationID else {
            throw Error.missingConversation
        }
        generateTask = try API.shared.generate(
            conversationID: conversationID,
            prompt: prompt,
            context: context,
            images: images,
            toolChoice: toolChoice,
            agentID: agentID
        )
        try await generateTask?.value
    }

    /// Generate an image from a given prompt. This is an explicit way to generate an image, most happen through tool use.
    func generate(image prompt: String) async throws {
        guard let conversationID else {
            throw Error.missingConversation
        }
        generateTask = try API.shared.generate(
            conversationID: conversationID,
            image: prompt
        )
        try await generateTask?.value
    }

    func cancel() {
        generateTask?.cancel()
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
                let runID = (message.runID != nil && !message.runID!.isEmpty) ? message.runID! : message.id
                currentRun = Run(
                    id: runID,
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
