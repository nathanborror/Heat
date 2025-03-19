import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Agents", category: "Providers")

public struct Agent: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var name: String
    public var instructions: String
    public var context: [String: Value]     // Context variables that will be injected into the instructions prompt
    public var tags: [String]               // XML tags that are expected in the output
    public var toolIDs: Set<String>
    public var created: Date
    public var modified: Date

    public enum Kind: String, Codable, Sendable, CaseIterable {
        case assistant
        case prompt
    }

    public init(id: String = .id, kind: Kind, name: String, instructions: String, context: [String: Value] = [:],
                tags: [String] = [], toolIDs: Set<String> = []) {
        self.id = id
        self.kind = kind
        self.name = name
        self.instructions = instructions
        self.context = context
        self.tags = tags
        self.toolIDs = toolIDs
        self.created = .now
        self.modified = .now
    }

    public static var empty: Self {
        .init(kind: .prompt, name: "", instructions: "")
    }

    mutating func apply(agent: Agent) {
        kind = agent.kind
        name = agent.name
        instructions = agent.instructions
        context = agent.context
        tags = agent.tags
        toolIDs = agent.toolIDs
        modified = .now
    }
}

@MainActor @Observable
public final class AgentsProvider {
    public static let shared = AgentsProvider()

    public private(set) var agents: [Agent] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error, CustomStringConvertible {
        case notFound(String)
        case persistenceError(String)

        public var description: String {
            switch self {
            case .notFound(let id):
                "Agent not found: \(id)"
            case .persistenceError(let detail):
                "Agent persistence error: \(detail)"
            }
        }
    }

    private let store: DataStore<[Agent]>
    private var storeRestoreTask: Task<Void, Never>?

    private init(location: String? = nil) {
        self.store = .init(location: location ?? ".app/agents")
        self.storeRestoreTask = Task { await restore() }
    }

    private func restore() async {
        do {
            agents = try await store.read() ?? []
            ping()
        } catch {
            logger.error("[AgentsProvider] Error restoring: \(error)")
        }
    }

    private func save() async throws {
        do {
            try await store.write(agents)
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

extension AgentsProvider {

    public func get(_ id: String) throws -> Agent {
        guard let agent = agents.first(where: { $0.id == id }) else {
            throw Error.notFound(id)
        }
        return agent
    }

    public func upsert(_ agent: Agent) async throws {
        await ready()
        var agents = self.agents
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var existing = agents[index]
            existing.apply(agent: agent)
            agents[index] = existing
        } else {
            agents.insert(agent, at: 0)
        }
        self.agents = agents
        try await save()
    }

    public func delete(_ id: String) async throws {
        await ready()
        agents.removeAll(where: { $0.id == id })
        try await save()
    }

    public func reset() async throws {
        agents = Defaults.agents
        try await save()
    }
}
