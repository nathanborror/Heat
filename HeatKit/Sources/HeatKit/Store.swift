import Foundation
import Observation
import OllamaKit

@Observable
public final class Store {
    
    public static let shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var agents: [Agent] = []
    public private(set) var chats: [AgentChat] = []
    public private(set) var models: [Model] = []
    public var preferences: Preferences = .init()

    private var client = OllamaClient()
    private var persistence: Persistence
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    public func generate(model: Model, prompt: String, system: String?, context: [Int]) async throws -> GenerateResponse {
        let request = GenerateRequest(model: model.name, prompt: prompt, system: system, context: context)
        let response = try await client.generate(request: request)
        return response
    }
    
    public func generateStream(model: Model, prompt: String, system: String?, context: [Int], callback: (GenerateResponse) async -> Void) async throws {
        let request = GenerateRequest(model: model.name, prompt: prompt, system: system, context: context)
        for try await response in client.generateStream(request: request) {
            await callback(response)
        }
    }
    
    public func models() async throws {
        let resp = try await client.modelList()
        self.models = resp.models.map { Model(name: $0.name, size: $0.size, digest: $0.digest) }
        
        for model in models { // Load and cache model info
            try await modelShow(modelID: model.name)
        }
    }
    
    public func modelShow(modelID: String) async throws {
        let request = ModelShowRequest(name: modelID)
        do {
            let modelDetails = try await client.modelShow(request: request)
            await upsert(modelDetails: modelDetails, modelID: modelID)
        } catch {
            print(error)
        }
    }
    
    public func modelPull(name: String, callback: (ProgressResponse) async -> Void) async throws {
        let request = ModelPullRequest(name: name)
        for try await response in client.modelPull(request: request) {
            await callback(response)
        }
    }
}

extension Store {
    
    public func createAgent(modelID: String, name: String, tagline: String, picture: Media = .none, system: String) -> Agent {
        .init(modelID: modelID, name: name, tagline: tagline, picture: picture, system: system)
    }
    
    public func createChat(agentID: String) -> AgentChat {
        guard let agent = get(agentID: agentID) else {
            fatalError("Agent does not exist")
        }
        return AgentChat(modelID: agent.modelID, agentID: agent.id, system: agent.system)
    }
    
    public func createMessage(kind: Message.Kind = .none, role: Message.Role, content: String, done: Bool = true) -> Message {
        return .init(kind: kind, role: role, content: content, done: done)
    }
}

extension Store {
    
    public func get(modelID: String) -> Model? {
        models.first(where: { $0.id == modelID })
    }
    
    public func get(agentID: String) -> Agent? {
        agents.first(where: { $0.id == agentID })
    }
    
    public func get(chatID: String) -> AgentChat? {
        chats.first(where: { $0.id == chatID })
    }
}

@MainActor
extension Store {
    
    public func upsert(modelDetails: ModelShowResponse, modelID: String) {
        if let index = models.firstIndex(where: { $0.id == modelID }) {
            models[index].license = modelDetails.license
            models[index].modelfile = modelDetails.modelfile
            models[index].parameters = modelDetails.parameters
            models[index].template = modelDetails.template
            models[index].system = modelDetails.system
        }
    }
    
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
        do {
            let agents: [Agent] = try await persistence.load(objects: "agents.json")
            let chats: [AgentChat] = try await persistence.load(objects: "chats.json")
            let models: [Model] = try await persistence.load(objects: "models.json")
            let preferences: Preferences? = try await persistence.load(object: "preferences.json")
            
            DispatchQueue.main.async {
                self.agents = agents
                self.chats = chats
                self.models = models
                self.preferences = preferences ?? self.preferences
                self.client = OllamaClient(host: self.preferences.host)
                
                if self.agents.isEmpty {
                    self.agents = self.defaultAgents
                }
            }
        } catch is DecodingError {
            try deleteAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: "agents.json", objects: agents)
        try await persistence.save(filename: "chats.json", objects: chats)
        try await persistence.save(filename: "models.json", objects: models)
        try await persistence.save(filename: "preferences.json", object: preferences)
    }
    
    public func deleteAll() throws {
        try persistence.delete(filename: "agents.json")
        try persistence.delete(filename: "chats.json")
        try persistence.delete(filename: "models.json")
        try persistence.delete(filename: "preferences.json")
        
        resetAll()
    }
    
    public func resetAll() {
        self.agents = defaultAgents
        self.chats = []
        self.models = []
        self.preferences = .init()
        self.client = OllamaClient()
    }
    
    private var defaultAgents: [Agent] { [.uhura, .richardFeynman, .theMoon, .grimes] }
}
