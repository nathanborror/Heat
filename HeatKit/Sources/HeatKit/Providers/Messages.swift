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
        case notFound(Message.ID)
        case persistenceError(String)

        public var description: String {
            switch self {
            case .notFound(let id):
                "Message not found: \(id.rawValue)"
            case .persistenceError(let detail):
                "Message persistence error: \(detail)"
            }
        }
    }

    private let store: DataStore<[Message]>
    private var storeRestoreTask: Task<Void, Never>?

    private init(location: String? = nil) {
        self.store = .init(location: location ?? ".app/messages")
        self.storeRestoreTask = Task { await restore() }
    }

    private func restore() async {
        do {
            messages = try await store.read() ?? []
            ping()
        } catch {
            logger.error("[MessagesProvider] Error restoring: \(error)")
        }
    }

    private func save() async throws {
        do {
            try await store.write(messages)
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

extension MessagesProvider {

    public func get(_ id: Message.ID) throws -> Message {
        guard let message = messages.first(where: { $0.id == id }) else {
            throw Error.notFound(id)
        }
        return message
    }

    public func get(referenceID: String) throws -> [Message] {
        messages.filter { $0.referenceID == referenceID }
    }

    public func upsert(messages: [Message], referenceID: String) async throws {
        await ready()
        for message in messages {
            try await upsert(message: message, referenceID: referenceID)
        }
    }

    public func upsert(message: Message, referenceID: String) async throws {
        await ready()
        var message = message
        message.referenceID = referenceID
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        ping() // intentionally not saving here due to streaming
    }

    public func delete(_ id: Message.ID) async throws {
        await ready()
        messages.removeAll(where: { $0.id == id })
        try await save()
    }

    public func delete(referenceID: String) async throws {
        await ready()
        messages.removeAll(where: { $0.referenceID == referenceID })
        try await save()
    }

    public func reset() async throws {
        messages = []
        try await save()
    }

    public func flush() async throws {
        await ready()
        try await save()
    }
}
