import GenKit
import HeatKit
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "ConversationViewModel", category: "App")

@MainActor @Observable
final class ConversationViewModel {
    var conversationID: Conversation.ID? = nil

    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared

    enum Error: Swift.Error, CustomStringConvertible {
        case generationError(String)
        case unexpectedError(String)

        public var description: String {
            switch self {
            case .generationError(let detail):
                return "Generation error: \(detail)"
            case .unexpectedError(let detail):
                return "Unexpected error: \(detail)"
            }
        }
    }

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
        let instructions = Message(role: .system, content: [.text(conversation.instructions)])
        return [instructions]
    }

    /// The whole conversation history.
    var messages: [Message] {
        guard let conversationID else { return [] }
        let history = try? messagesProvider.get(referenceID: conversationID.rawValue)
        return history ?? []
    }

    /// The conversation history aggregated by Run which packages up all tool calls and responses into a Run.
    var runs: [Run] {
        guard conversationID != nil else { return [] }
        return prepareRuns()
    }

    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    func generate(chat prompt: String, images: [Data] = [], context: [String: String] = [:], toolChoice: Tool? = nil, agentID: Agent.ID? = nil) async throws {
        guard let conversationID else { return }
        do {
            try await API.shared.generate(
                conversationID: conversationID,
                prompt: prompt,
                context: context,
                images: images,
                toolChoice: toolChoice,
                agentID: agentID
            ).value
        } catch {
            throw Error.generationError("\(error)")
        }
    }

    /// Generate an image from a given prompt. This is an explicit way to generate an image, most happen through tool use.
    func generate(image prompt: String) async throws {
        guard let conversationID else { return }
        do {
            try await API.shared.generate(
                conversationID: conversationID,
                image: prompt
            ).value
        } catch {
            throw Error.generationError("Image generation failed: \(error)")
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
