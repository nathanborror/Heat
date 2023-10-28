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
}

extension Store {
    
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
    
    public func loadModels() async throws {
        let resp = try await client.modelList()
        self.models = resp.models.map { Model(name: $0.name, size: $0.size, digest: $0.digest) }
        
        for model in models {
            await upsert(model: model)
        }
    }
    
    public func loadModelDetails() async throws {
        for model in self.models {
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
    
    public func createAgent(name: String, picture: Media = .none, prompt: String) -> Agent {
        .init(name: name, picture: picture, prompt: prompt)
    }
    
    public func createChat(modelID: String, agentID: String) -> AgentChat {
        guard let agent = get(agentID: agentID) else {
            fatalError("Agent does not exist")
        }
        return AgentChat(modelID: modelID, agentID: agent.id, system: agent.system)
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
    
    public func getDefaultModel(_ prefixes: [String] = ["mistral", "mistral:instruct", "llama2:7b-chat"]) -> Model? {
        for prefix in prefixes {
            guard let model = models.first(where: { $0.id == prefix }) else { continue }
            return model
        }
        return nil
    }
}

@MainActor
extension Store {
    
    public func upsert(model: Model) {
        if let index = models.firstIndex(where: { $0.id == model.name }) {
            let existing = models[index]
            models[index] = existing
        } else {
            models.append(model)
        }
    }
    
    public func upsert(modelDetails: ModelShowResponse, modelID: String) {
        if let index = models.firstIndex(where: { $0.id == modelID }) {
            var existing = models[index]
            existing.license = modelDetails.license
            existing.modelfile = modelDetails.modelfile
            existing.parameters = modelDetails.parameters
            existing.template = modelDetails.template
            existing.system = modelDetails.system
            models[index] = existing
        }
    }
    
    public func upsert(agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var agent = agent
            agent.modified = .now
            agents[index] = agent
        } else {
            agents.append(agent)
        }
    }
    
    public func upsert(chat: AgentChat, context: [Int]? = nil) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            var chat = chat
            chat.modified = .now
            chats[index] = chat
        } else {
            chats.append(chat)
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
                self.agents = agents.isEmpty ? self.defaultAgents : agents
                self.chats = chats
                self.models = models
                self.preferences = preferences ?? self.preferences
                self.client = OllamaClient(host: self.preferences.host)
            }
        } catch is DecodingError {
            try await deleteAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: "agents.json", objects: agents)
        try await persistence.save(filename: "chats.json", objects: chats)
        try await persistence.save(filename: "models.json", objects: models)
        try await persistence.save(filename: "preferences.json", object: preferences)
    }
    
    public func deleteAll() async throws {
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
        self.client = OllamaClient(host: preferences.host)
    }
    
    public func resetAgents() async throws {
        self.agents = defaultAgents
    }
    
    private var defaultAgents: [Agent] {
        [
            .vent,
            .learn,
            .brainstorm,
            .advice,
            .anxious,
            .philisophical,
            .discover,
            .coach,
            .journal,
            .assistant,
        ]
    }
}

extension Store {
    
    public static var preview: Store {
        let store = Store.shared
        store.resetAll()
        return store
    }
    
    public static var previewChats: Store {
        let store = Store.shared
        store.resetAll()
        
        let chat1 = store.createChat(modelID: "none", agentID: Agent.vent.id)
        let chat2 = store.createChat(modelID: "none", agentID: Agent.learn.id)
        let chat3 = store.createChat(modelID: "none", agentID: Agent.brainstorm.id)
        
        Task {
            await store.upsert(chat: chat1)
            await store.upsert(chat: chat2)
            await store.upsert(chat: chat3)
        }
        return store
    }
}
