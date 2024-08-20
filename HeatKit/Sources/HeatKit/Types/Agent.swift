// An agent is a helpful set of instructions that kicks off a conversation. The messages that accompany an agent
// help orient a conversation. It can improve utility and/or entertainment of an experience.

import Foundation
import GenKit
import SharedKit

public struct Agent: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var instructions: [Message]
    public var toolIDs: Set<String>
    public var created: Date
    public var modified: Date
    
    public init(id: String = .id, name: String, instructions: [Message] = [], toolIDs: Set<String> = []) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.toolIDs = toolIDs
        self.created = .now
        self.modified = .now
    }
    
    public static var empty: Self {
        .init(name: "")
    }
    
    mutating func apply(agent: Agent) {
        name = agent.name
        instructions = agent.instructions
        toolIDs = agent.toolIDs
        modified = .now
    }
}

actor AgentData {
    private var agents: [Agent] = []
    
    func save(_ agents: [Agent]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(agents)
        try data.write(to: self.dataURL, options: [.atomic])
        self.agents = agents
    }
    
    func load() throws -> [Agent] {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        agents = try decoder.decode([Agent].self, from: data)
        return agents
    }
    
    private var dataURL: URL {
        get throws {
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("AgentData.plist")
        }
    }
}

@MainActor
@Observable
public class AgentStore {
    public static let shared = AgentStore()
    
    public private(set) var agents: [Agent] = []
    
    public func get(_ id: String) throws -> Agent {
        guard let agent = agents.first(where: { $0.id == id }) else {
            throw AgentStoreError.notFound
        }
        return agent
    }
    
    public func upsert(agent: Agent) async throws {
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
        let agent = try get(id)
        agents.removeAll(where: { agent == $0 })
        try await save()
    }
    
    // MARK: - Private
    
    private let data = AgentData()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        self.agents = try await data.load()
    }
    
    private func save() async throws {
        try await data.save(agents)
    }
}

public enum AgentStoreError: Error {
    case notFound
}
