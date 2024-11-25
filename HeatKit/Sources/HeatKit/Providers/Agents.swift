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
    public var context: [String: String]    // Context variables that will be injected into the instructions prompt
    public var tags: [String]               // XML tags that are expected in the output
    public var toolIDs: Set<String>
    public var created: Date
    public var modified: Date
    
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case assistant
        case prompt
    }
    
    public init(id: String = .id, kind: Kind, name: String, instructions: String, context: [String: String] = [:],
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

    public enum Error: Swift.Error {
        case notFound
    }

    private let agentStore: PropertyStore<[Agent]>
    private var agentInitTask: Task<Void, Swift.Error>?

    private init(location: String? = nil) {
        self.agentStore = .init(location: location ?? ".app/agents")
        self.agentInitTask = Task {
            try await load()
        }
    }

    private func load() async throws {
        agents = try await agentStore.read() ?? []
        ping()
    }

    private func save() async throws {
        try await agentStore.write(agents)
        ping()
    }

    // Update the `updated` timestamp and may do other things in the future.
    private func ping() {
        updated = .now
    }

    // Ensures cached data has loaded before continuing.
    private func ready() async throws {
        if let task = agentInitTask {
            try await task.value
        }
    }
}

extension AgentsProvider {

    public func get(_ id: String) throws -> Agent {
        guard let agent = agents.first(where: { $0.id == id }) else {
            throw Error.notFound
        }
        return agent
    }
    
    public func upsert(_ agent: Agent) async throws {
        try await ready()
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
        try await ready()
        agents.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func reset() async throws {
        try await ready()
        agents = Defaults.agents
        try await save()
        logger.debug("[AgentsProvider] Reset")
    }
    
    public func flush() async throws {
        try await ready()
        try await save()
    }
}
