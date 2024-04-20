// An agent is a helpful set of instructions that kicks off a conversation. The messages that accompany an agent
// help orient a conversation. It can improve utility and/or entertainment of an experience.

import Foundation
import GenKit
import SharedKit

public struct Agent: Codable, Identifiable {
    public var id: String
    public var name: String
    public var instructions: [Message]
    public var tools: Set<Tool>
    public var created: Date
    public var modified: Date
    
    public init(id: String = .id, name: String, instructions: [Message], tools: Set<Tool> = []) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.tools = tools
        self.created = .now
        self.modified = .now
    }
    
    mutating func apply(agent: Agent) {
        self.name = agent.name
        self.instructions = agent.instructions
        self.tools = agent.tools
        self.modified = .now
    }
    
    public static var empty: Self {
        .init(name: "", instructions: [])
    }
}

extension Agent: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Agent {
    
    public static var preview: Self = {
        .init(
            id: "bundle-assistant",
            name: "Assistant",
            instructions: [
                .init(kind: .instruction, role: .system, content: "You are a helpful assistant.")
            ]
        )
    }()
}

/// Used to import agents from a YAML file located in the build resources.
struct AgentsResource: Decodable {
    let agents: [AgentResource]
    
    struct AgentResource: Decodable {
        let id: String
        let name: String
        let tagline: String?
        let kind: String?
        let categories: [String]?
        let instructions: [MessageResource]
        let tools: [String]?
        
        struct MessageResource: Decodable {
            let role: String
            let content: String
        }
        
        var encode: Agent {
            .init(
                id: id,
                name: name,
                instructions: encodeInstructions,
                tools: Set(encodeTools)
            )
        }
        
        var encodeTools: [Tool] {
            tools?.map { name -> Tool? in
                switch name {
                case Tool.generateWebSearch.function.name:
                    return Tool.generateWebSearch
                case Tool.generateWebBrowse.function.name:
                    return Tool.generateWebBrowse
                case Tool.generateImages.function.name:
                    return Tool.generateImages
                default:
                    return nil
                }
            }.compactMap { $0 } ?? []
        }
        
        var encodeInstructions: [Message] {
            instructions.map { .init(kind: .instruction, role: .init(rawValue: $0.role)!, content: $0.content) }
        }
    }
}
