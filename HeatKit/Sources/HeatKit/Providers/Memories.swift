import Foundation
import OSLog
import SharedKit

private let logger = Logger(subsystem: "Memory", category: "Kit")

public struct Memory: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var content: String
    public var created: Date
    public var modified: Date

    public enum Kind: String, Codable, Sendable {
        case personal
        case interest
        case none
    }

    public init(id: String = .id, kind: Kind = .none, content: String) {
        self.id = id
        self.kind = kind
        self.content = content
        self.created = .now
        self.modified = .now
    }

    mutating func apply(memory: Memory) {
        kind = memory.kind
        content = memory.content
        modified = .now
    }
}

@MainActor @Observable
public final class MemoryProvider {
    public static let shared = MemoryProvider()

    public private(set) var memories: [Memory] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error, CustomStringConvertible {
        case notFound(String)
        case persistenceError(String)

        public var description: String {
            switch self {
            case .notFound(let id):
                "Memory not found: \(id)"
            case .persistenceError(let detail):
                "Memory persistence error: \(detail)"
            }
        }
    }

    private let store: DataStore<[Memory]>
    private var storeRestoreTask: Task<Void, Never>?

    private init(location: String? = nil) {
        self.store = .init(location: location ?? ".app/memories")
        self.storeRestoreTask = Task { await restore() }
    }

    private func restore() async {
        do {
            memories = try await store.read() ?? []
            ping()
        } catch {
            logger.error("[MemoryProvider] Error restoring: \(error)")
        }
    }

    private func save() async throws {
        do {
            try await store.write(memories)
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

extension MemoryProvider {

    public func get(_ id: String) throws -> Memory {
        guard let memory = memories.first(where: { $0.id == id }) else {
            throw Error.notFound(id)
        }
        return memory
    }

    public func upsert(_ memory: Memory) async throws {
        await ready()
        var memories = self.memories
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            var existing = memories[index]
            existing.apply(memory: memory)
            memories[index] = existing
        } else {
            memories.insert(memory, at: 0)
        }
        self.memories = memories
        try await save()
    }

    public func delete(_ id: String) async throws {
        await ready()
        memories.removeAll(where: { $0.id == id })
        try await save()
    }

    public func reset() async throws {
        memories = []
        try await save()
    }
}
