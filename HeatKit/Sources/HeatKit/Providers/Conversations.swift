import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Conversations", category: "Providers")

public struct Conversation: Codable, Identifiable, Sendable {
    public var id: String
    public var title: String?
    public var subtitle: String?
    public var picture: Asset?
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
    
    public init(id: String = .id, title: String? = nil, subtitle: String? = nil, picture: Asset? = nil,
                instructions: String = "", suggestions: [String] = [], toolIDs: Set<String> = [], state: State = .none) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.picture = picture
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
        self.picture = conversation.picture
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
        case notFound
    }

    private let conversationStore: PropertyStore<[Conversation]>
    private var conversationInitTask: Task<Void, Swift.Error>?

    private init(location: String? = nil) {
        self.conversationStore = .init(location: location ?? ".app/conversations")
        self.conversationInitTask = Task {
            try await load()
        }
    }

    private func load() async throws {
        self.conversations = try await conversationStore.read() ?? []
        ping()
    }

    private func save() async throws {
        try await conversationStore.write(conversations)
        ping()
    }

    // Update the `updated` timestamp and may do other things in the future.
    private func ping() {
        updated = .now
    }

    // Ensures cached data has loaded before continuing.
    private func ready() async throws {
        if let task = conversationInitTask {
            try await task.value
        }
    }
}

extension ConversationsProvider {

    public func get(_ id: String) throws -> Conversation {
        guard let conversation = conversations.first(where: { $0.id == id }) else {
            throw Error.notFound
        }
        return conversation
    }
    
    public func create(instructions: String, toolIDs: Set<String>, state: Conversation.State = .none) async throws -> Conversation {
        let conversation = Conversation(instructions: instructions, toolIDs: toolIDs, state: state)
        try await upsert(conversation)
        return conversation
    }
    
    public func upsert(_ conversation: Conversation) async throws {
        try await ready()
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
        try await ready()
        var conversation = try get(conversationID)
        conversation.title = title.isEmpty ? nil : title
        try await upsert(conversation)
    }
    
    public func upsert(instructions: String, conversationID: String) async throws {
        try await ready()
        var conversation = try get(conversationID)
        conversation.instructions = instructions
        try await upsert(conversation)
    }
    
    public func upsert(suggestions: [String], conversationID: String) async throws {
        try await ready()
        var conversation = try get(conversationID)
        conversation.suggestions = suggestions
        try await upsert(conversation)
    }
    
    public func upsert(state: Conversation.State, conversationID: String) async throws {
        try await ready()
        var conversation = try get(conversationID)
        conversation.state = state
        try await upsert(conversation)
    }
    
    public func delete(_ id: String) async throws {
        try await ready()
        conversations.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func reset() async throws {
        try await ready()
        conversations = []
        try await save()
        logger.debug("[ConversationsProvider] Reset")
    }
    
    public func flush() async throws {
        try await ready()
        try await save()
    }
}
