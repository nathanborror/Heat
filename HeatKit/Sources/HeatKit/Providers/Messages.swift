import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Messages", category: "Providers")

actor MessageStore {
    private var messages: [Message] = []
    
    func save(_ messages: [Message]) throws {
        logger.debug("[MessageStore] Saving \(Self.dataURL.absoluteString)")

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(messages)
        try data.write(to: Self.dataURL, options: [.atomic])
        self.messages = messages
    }
    
    func load() throws -> [Message] {
        logger.debug("[MessageStore] Loading \(Self.dataURL.absoluteString)")

        let data = try Data(contentsOf: Self.dataURL)
        let decoder = PropertyListDecoder()
        messages = try decoder.decode([Message].self, from: data)
        return messages
    }
    
    private static let dataURL = {
        let dir = URL.documentsDirectory.appending(path: ".app", directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("messages", conformingTo: .propertyList)
    }()
}

@MainActor @Observable
public final class MessagesProvider {
    public static let shared = MessagesProvider()
    
    public private(set) var messages: [Message] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error {
        case notFound
    }

    public func get(_ id: Message.ID) throws -> Message {
        guard let message = messages.first(where: { $0.id == id }) else {
            throw Error.notFound
        }
        return message
    }
    
    public func get(parentID: String) throws -> [Message] {
        messages.filter { $0.parent == parentID }
    }
    
    public func upsert(messages: [Message], parentID: String) async throws {
        for message in messages {
            try await upsert(message: message, parentID: parentID)
        }
    }
    
    public func upsert(message: Message, parentID: String) async throws {
        var message = message
        message.parent = parentID
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        ping() // intentionally not saving here due to streaming
    }
    
    public func delete(_ id: Message.ID) async throws {
        messages.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func delete(parentID: String) async throws {
        messages.removeAll(where: { $0.parent == parentID })
        try await save()
    }
    
    public func reset() async throws {
        messages = []
        try await save()
        logger.debug("[MessagesProvider] Reset")
    }
    
    public func flush() async throws {
        try await save()
    }
    
    public func ping() {
        updated = .now
    }
    
    // MARK: - Private
    
    private let conversationStore = ConversationStore()
    private let messageStore = MessageStore()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        messages = try await messageStore.load()
        ping()
    }
    
    private func save() async throws {
        try await messageStore.save(messages)
        ping()
    }
}
