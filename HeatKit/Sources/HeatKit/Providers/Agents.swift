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

actor AgentStore {
    private var agents: [Agent] = []
    
    func save(_ agents: [Agent]) throws {
        logger.debug("[AgentStore] Saving \(Self.dataURL.absoluteString)")

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(agents)
        try data.write(to: Self.dataURL, options: [.atomic])
        self.agents = agents
    }
    
    func load() throws -> [Agent] {
        logger.debug("[AgentStore] Loading \(Self.dataURL.absoluteString)")

        let data = try Data(contentsOf: Self.dataURL)
        let decoder = PropertyListDecoder()
        agents = try decoder.decode([Agent].self, from: data)
        return agents
    }
    
    private static let dataURL = {
        let dir = URL.documentsDirectory.appending(path: ".app", directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("agents", conformingTo: .propertyList)
    }()
}

@MainActor @Observable
public final class AgentsProvider {
    public static let shared = AgentsProvider()
    
    public private(set) var agents: [Agent] = []
    public private(set) var updated: Date = .now

    public enum Error: Swift.Error {
        case notFound
    }

    public func get(_ id: String) throws -> Agent {
        guard let agent = agents.first(where: { $0.id == id }) else {
            throw Error.notFound
        }
        return agent
    }
    
    public func upsert(_ agent: Agent) async throws {
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
        agents.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func reset() async throws {
        agents = Defaults.agents
        try await save()
        logger.debug("[AgentsProvider] Reset")
    }
    
    public func flush() async throws {
        try await save()
    }
    
    // MARK: - Private
    
    private let store = AgentStore()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        agents = try await store.load()
        ping()
    }
    
    private func save() async throws {
        try await store.save(agents)
        ping()
    }
    
    public func ping() {
        updated = .now
    }
}
