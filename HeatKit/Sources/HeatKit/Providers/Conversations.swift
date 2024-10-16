import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Conversations", category: "Kit")

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

actor ConversationStore {
    private var conversations: [Conversation] = []
    
    func save(_ conversations: [Conversation]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(conversations)
        try data.write(to: self.dataURL, options: [.atomic])
        self.conversations = conversations
    }
    
    func load() throws -> [Conversation] {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        conversations = try decoder.decode([Conversation].self, from: data)
        return conversations
    }
    
    private var dataURL: URL {
        get throws {
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("ConversationData.plist")
        }
    }
}

@MainActor
@Observable
public final class ConversationsProvider {
    public static let shared = ConversationsProvider()
    
    public private(set) var conversations: [Conversation] = []
    public private(set) var updated: Date = .now
    
    public func get(_ id: String) throws -> Conversation {
        guard let conversation = conversations.first(where: { $0.id == id }) else {
            throw ConversationsProviderError.notFound
        }
        return conversation
    }
    
    public func create(instructions: String, toolIDs: Set<String>, state: Conversation.State = .none) async throws -> Conversation {
        let conversation = Conversation(instructions: instructions, toolIDs: toolIDs, state: state)
        try await upsert(conversation)
        return conversation
    }
    
    public func upsert(_ conversation: Conversation) async throws {
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
        var conversation = try get(conversationID)
        conversation.title = title.isEmpty ? nil : title
        try await upsert(conversation)
    }
    
    public func upsert(instructions: String, conversationID: String) async throws {
        var conversation = try get(conversationID)
        conversation.instructions = instructions
        try await upsert(conversation)
    }
    
    public func upsert(suggestions: [String], conversationID: String) async throws {
        var conversation = try get(conversationID)
        conversation.suggestions = suggestions
        try await upsert(conversation)
    }
    
    public func upsert(state: Conversation.State, conversationID: String) async throws {
        var conversation = try get(conversationID)
        conversation.state = state
        try await upsert(conversation)
    }
    
    public func delete(_ id: String) async throws {
        conversations.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func reset() async throws {
        logger.debug("Resetting conversations...")
        conversations = []
        try await save()
    }
    
    public func flush() async throws {
        try await save()
    }
    
    // MARK: - Private
    
    private let conversationStore = ConversationStore()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        self.conversations = try await conversationStore.load()
        ping()
    }
    
    private func save() async throws {
        try await conversationStore.save(conversations)
        ping()
    }
    
    private func ping() {
        updated = .now
    }
}

public enum ConversationsProviderError: Error {
    case notFound
}
