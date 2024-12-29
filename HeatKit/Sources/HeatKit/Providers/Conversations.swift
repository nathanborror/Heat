import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Conversations", category: "Providers")

public struct Conversation: Codable, Identifiable, Sendable {
    public var id: String
    public var title: String?
    public var subtitle: String?
    public var instructions: String
    public var suggestions: [String]
    public var toolIDs: Set<String>
    public var state: State
    public var created: Date
    public var modified: Date

    public enum State: Codable, Sendable {
        case processing
        case streaming
        case suggesting
        case none
    }

    public init(id: String = .id, title: String? = nil, subtitle: String? = nil, instructions: String = "",
                suggestions: [String] = [], toolIDs: Set<String> = [], state: State = .none) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.instructions = instructions
        self.suggestions = suggestions
        self.toolIDs = toolIDs
        self.state = state
        self.created = .now
        self.modified = .now
    }

    mutating func apply(conversation: Conversation) {
        self.title = conversation.title
        self.subtitle = conversation.subtitle
        self.instructions = conversation.instructions
        self.suggestions = conversation.suggestions
        self.toolIDs = conversation.toolIDs
        self.state = conversation.state
        self.modified = .now
    }

    public static var empty: Self {
        .init()
    }
}

@MainActor @Observable
public final class ConversationsProvider {
    public static let shared = ConversationsProvider()

    public private(set) var conversations: [Conversation] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error {
        case notFound(String)
        case persistenceError(String)

        public var description: String {
            switch self {
            case .notFound(let id):
                "Conversation not found: \(id)"
            case .persistenceError(let detail):
                "Conversation persistence error: \(detail)"
            }
        }
    }

    private let store: DataStore<[Conversation]>
    private var storeRestoreTask: Task<Void, Never>?

    private init(location: String? = nil) {
        self.store = .init(location: location ?? ".app/conversations")
        self.storeRestoreTask = Task { await restore() }
    }

    private func restore() async {
        do {
            self.conversations = try await store.read() ?? []
            ping()
        } catch {
            logger.error("[ConversationsProvider] Error restoring: \(error)")
        }
    }

    private func save() async throws {
        do {
            try await store.write(conversations)
            ping()
        } catch {
            throw Error.persistenceError("\(error)")
        }
    }

    private func ping() {
        updated = .now
    }

    public func ready() async {
        await storeRestoreTask?.value
    }
}

extension  ConversationsProvider {

    public func get(_ id: String) throws -> Conversation {
        guard let conversation = conversations.first(where: { $0.id == id }) else {
            throw Error.notFound(id)
        }
        return conversation
    }

    public func create(instructions: String, toolIDs: Set<String>, state: Conversation.State = .none) async throws -> Conversation {
        let conversation = Conversation(instructions: instructions, toolIDs: toolIDs, state: state)
        try await upsert(conversation)
        return conversation
    }

    public func upsert(_ conversation: Conversation) async throws {
        await ready()
        var conversations = self.conversations
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var existing = conversations[index]
            existing.apply(conversation: conversation)
            conversations[index] = existing
        } else {
            conversations.insert(conversation, at: 0)
        }
        self.conversations = conversations
        try await save()
    }

    public func upsert(title: String, conversationID: String) async throws {
        await ready()
        var conversation = try get(conversationID)
        conversation.title = title.isEmpty ? nil : title
        try await upsert(conversation)
    }

    public func upsert(instructions: String, conversationID: String) async throws {
        await ready()
        var conversation = try get(conversationID)
        conversation.instructions = instructions
        try await upsert(conversation)
    }

    public func upsert(suggestions: [String], conversationID: String) async throws {
        await ready()
        var conversation = try get(conversationID)
        conversation.suggestions = suggestions
        try await upsert(conversation)
    }

    public func upsert(state: Conversation.State, conversationID: String) async throws {
        await ready()
        var conversation = try get(conversationID)
        conversation.state = state
        try await upsert(conversation)
    }

    public func delete(_ id: String) async throws {
        await ready()
        conversations.removeAll(where: { $0.id == id })
        try await save()
    }

    public func reset() async throws {
        conversations = []
        try await save()
    }
}
