import Foundation
import Observation
import OllamaKit

@Observable
public final class Store {
    
    public static let shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var agents: [Agent] = [.grimes, .richardFeynman, .theMoon]
    public private(set) var chats: [AgentChat] = []
    public private(set) var models: [Model] = []
    public private(set) var preferences: Preferences = .init()

    private var client = OllamaClient()
    private var persistence: Persistence
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    public func generate(model: String, prompt: String, system: String, context: [Int]) async throws -> GenerateResponse {
        let request = GenerateRequest(model: model, prompt: prompt, system: system, context: context)
        let response = try await client.generate(request: request)
        return response
    }
    
    public func generateStream(model: String, prompt: String, system: String, context: [Int], callback: (GenerateResponse) async -> Void) async throws {
        let request = GenerateRequest(model: model, prompt: prompt, system: system, context: context)
        for try await response in client.generateStream(request: request) {
            await callback(response)
        }
    }
    
    public func models() async throws {
        let resp = try await client.tags()
        self.models = resp.models.map { Model(name: $0.name, size: $0.size, digest: $0.digest) }
    }
}

extension Store {
    
    public func createAgent(name: String, tagline: String, picture: Media = .none, system: String) -> Agent {
        .init(name: name, tagline: tagline, picture: picture, system: system)
    }
    
    public func createChat(agentID: String) -> AgentChat {
        guard let agent = get(agentID: agentID) else {
            fatalError("Agent does not exist")
        }
        return AgentChat(agentID: agent.id, preferredModel: agent.preferredModel, system: agent.system)
    }
    
    public func createMessage(kind: Message.Kind = .none, role: Message.Role, content: String, done: Bool = true) -> Message {
        .init(model: preferences.model, kind: kind, role: role, content: content, done: done)
    }
}

extension Store {
    
    public func get(agentID: String) -> Agent? {
        agents.first(where: { $0.id == agentID })
    }
    
    public func get(chatID: String) -> AgentChat? {
        chats.first(where: { $0.id == chatID })
    }
}

@MainActor
extension Store {
    
    public func upsert(agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var agent = agent
            agent.modified = .now
            agents[index] = agent
        } else {
            self.agents.append(agent)
        }
    }
    
    public func upsert(chat: AgentChat, context: [Int]? = nil) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            var chat = chat
            chat.modified = .now
            chats[index] = chat
        } else {
            self.chats.append(chat)
        }
    }
    
    public func upsert(message: Message, chatID: String) {
        guard var chat = get(chatID: chatID) else { return }
        if let index = chat.messages.firstIndex(where: { $0.id == message.id }) {
            var existing = chat.messages[index]
            existing.content += message.content
            existing.done = message.done
            existing.modified = .now
            chat.messages[index] = existing
        } else {
            chat.messages.append(message)
        }
        upsert(chat: chat)
    }
    
    public func upsert(preferences: Preferences) {
        var preferences = preferences
        preferences.modified = .now
        self.preferences = preferences
        self.client = OllamaClient(host: self.preferences.host)
    }
    
    public func set(context: [Int]?, chatID: String) {
        guard var chat = get(chatID: chatID) else { return }
        guard let context = context else { return }
        chat.context = context
        upsert(chat: chat)
    }
    
    public func set(state: AgentChat.State, chatID: String) {
        guard var chat = get(chatID: chatID) else { return }
        chat.state = state
        upsert(chat: chat)
    }
    
    public func delete(chat: AgentChat) {
        chats.removeAll(where: { $0.id == chat.id })
    }
}

extension Store {
    
    public func restore() async throws {
        let agents: [Agent] = try await persistence.load(objects: "agents.json")
        let chats: [AgentChat] = try await persistence.load(objects: "chats.json")
        let preferences: Preferences? = try await persistence.load(object: "preferences.json")
        
        DispatchQueue.main.async {
            self.agents = agents
            self.chats = chats
            self.preferences = preferences ?? self.preferences
            self.client = OllamaClient(host: self.preferences.host)
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: "agents.json", objects: agents)
        try await persistence.save(filename: "chats.json", objects: chats)
        try await persistence.save(filename: "preferences.json", object: preferences)
    }
    
    public func deleteAll() throws {
        try persistence.delete(filename: "agents.json")
        try persistence.delete(filename: "chats.json")
        try persistence.delete(filename: "preferences.json")
        
        self.agents = []
        self.chats = []
        self.preferences = .init()
        self.client = OllamaClient()
    }
}
