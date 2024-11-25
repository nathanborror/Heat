import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Messages", category: "Providers")

@MainActor @Observable
public final class MessagesProvider {
    public static let shared = MessagesProvider()

    public private(set) var messages: [Message] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error {
        case notFound
    }

    private let messageStore: PropertyStore<[Message]>
    private var messageInitTask: Task<Void, Swift.Error>?

    private init(location: String? = nil) {
        self.messageStore = .init(location: location ?? ".app/messages")
        self.messageInitTask = Task {
            try await load()
        }
    }

    private func load() async throws {
        messages = try await messageStore.read() ?? []
        ping()
    }

    private func save() async throws {
        try await messageStore.write(messages)
        ping()
    }

    // Update the `updated` timestamp and may do other things in the future.
    private func ping() {
        updated = .now
    }

    // Ensures cached data has loaded before continuing.
    private func ready() async throws {
        if let task = messageInitTask {
            try await task.value
        }
    }
}

extension MessagesProvider {

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
        try await ready()
        for message in messages {
            try await upsert(message: message, parentID: parentID)
        }
    }
    
    public func upsert(message: Message, parentID: String) async throws {
        try await ready()
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
        try await ready()
        messages.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func delete(parentID: String) async throws {
        try await ready()
        messages.removeAll(where: { $0.parent == parentID })
        try await save()
    }
    
    public func reset() async throws {
        try await ready()
        messages = []
        try await save()
        logger.debug("[MessagesProvider] Reset")
    }
    
    public func flush() async throws {
        try await ready()
        try await save()
    }
}
