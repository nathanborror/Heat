import Foundation
import Observation
import OllamaKit

public enum StoreError: LocalizedError {
    case missingAgent
    case missingModel
}

@Observable
public final class Store {
    
    public static let shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var agents: [Agent] = []
    public private(set) var conversations: [Conversation] = []
    public private(set) var models: [Model] = []
    public var preferences: Preferences = .init()
    
    private var client = OllamaClient()
    private var persistence: Persistence
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }

    // API
    
    public func generate(model: Model, prompt: String, system: String?, context: [Int]) async throws -> GenerateResponse {
        let payload = GenerateRequest(model: model.name, prompt: prompt, system: system, context: context)
        let response = try await client.generate(payload)
        return response
    }
    
    public func generateStream(model: Model, prompt: String, system: String?, context: [Int], callback: (GenerateResponse) async -> Void) async throws {
        let payload = GenerateRequest(model: model.name, prompt: prompt, system: system, context: context)
        for try await response in client.generateStream(payload) {
            await callback(response)
        }
    }
    
    public func chat(model: Model, messages: [Message], format: String? = nil) async throws -> ChatResponse {
        let payload = ChatRequest(model: model.name, messages: encode(messages: messages), format: format)
        let response = try await client.chat(payload)
        return response
    }
    
    public func chatStream(model: Model, messages: [Message], format: String? = nil, callback: (ChatResponse) async throws -> Void) async throws {
        let payload = ChatRequest(model: model.name, messages: encode(messages: messages), stream: true, format: format)
        for try await response in client.chatStream(payload) {
            try await callback(response)
        }
    }
    
    public func modelsLoad() async throws {
        let resp = try await client.modelList()
        let models = resp.models.map { Model(name: $0.name, size: $0.size, digest: $0.digest) }
        await upsert(models: models)
    }
    
    public func modelShow(modelID: String) async throws {
        let payload = ModelShowRequest(name: modelID)
        do {
            let modelDetails = try await client.modelShow(payload)
            await upsert(modelDetails: modelDetails, modelID: modelID)
        } catch {
            print(error)
        }
    }
    
    public func modelPull(name: String, callback: (ProgressResponse) async -> Void) async throws {
        let payload = ModelPullRequest(name: name)
        for try await response in client.modelPull(payload) {
            await callback(response)
        }
    }

    // Creators
    
    public func createAgent(name: String, tagline: String, picture: Media = .none, messages: [Message]) -> Agent {
        .init(name: name, tagline: tagline, picture: picture, messages: messages)
    }
    
    public func createConversation(agentID: String? = nil) throws -> Conversation {
        var messages: [Message] = []
        if let agentID = agentID, let agent = get(agentID: agentID) {
            messages = agent.messages
        }
        guard let model = getPreferredModel() else {
            throw StoreError.missingModel
        }
        return Conversation(modelID: model.id, messages: messages)
    }
    
    public func createMessage(kind: Message.Kind = .none, role: Message.Role, content: String, done: Bool = true) -> Message {
        return .init(kind: kind, role: role, content: content, done: done)
    }

    // Getters
    
    public func get(modelID: String) -> Model? {
        models.first(where: { $0.id == modelID })
    }
    
    public func get(agentID: String) -> Agent? {
        agents.first(where: { $0.id == agentID })
    }
    
    public func get(conversationID: String) -> Conversation? {
        conversations.first(where: { $0.id == conversationID })
    }
    
    public func getPreferredModel(_ prefixes: [String] = ["mistral", "mistral:instruct", "llama2:7b-chat"]) -> Model? {
        if let model = get(modelID: preferences.preferredModelID) {
            return model
        }
        for prefix in prefixes {
            guard let model = models.first(where: { $0.id == prefix }) else { continue }
            return model
        }
        return nil
    }

    // Uperts

    @MainActor public func upsert(models: [Model]) {
        for model in models {
            upsert(model: model)
        }
    }
    
    @MainActor public func upsert(model: Model) {
        if let index = models.firstIndex(where: { $0.id == model.name }) {
            let existing = models[index]
            models[index] = existing
        } else {
            models.append(model)
        }
    }
    
    @MainActor public func upsert(modelDetails: ModelShowResponse, modelID: String) {
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
    
    @MainActor public func upsert(agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var agent = agent
            agent.modified = .now
            agents[index] = agent
        } else {
            agents.insert(agent, at: 0)
        }
    }
    
    @MainActor public func upsert(conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var conversation = conversation
            conversation.modified = .now
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
    }
    
    @MainActor public func upsert(message: Message, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else { return }
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            var existing = conversation.messages[index]
            existing.content += message.content
            existing.done = message.done
            existing.modified = .now
            conversation.messages[index] = existing
        } else {
            conversation.messages.append(message)
        }
        upsert(conversation: conversation)
    }
    
    @MainActor public func upsert(preferences: Preferences) {
        var preferences = preferences
        preferences.modified = .now
        self.preferences = preferences
        self.client = OllamaClient(host: self.preferences.host)
    }
    
    @MainActor public func set(state: Conversation.State, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else { return }
        conversation.state = state
        upsert(conversation: conversation)
    }
    
    @MainActor public func delete(conversation: Conversation) {
        conversations.removeAll(where: { $0.id == conversation.id })
    }

    // Persistence
    
    static private var agentsJSON = "agents.json"
    static private var conversationsJSON = "conversations.json"
    static private var modelsJSON = "models.json"
    static private var preferencesJSON = "preferences.json"
    
    public func restore() async throws {
        do {
            let agents: [Agent] = try await persistence.load(objects: Self.agentsJSON)
            let conversations: [Conversation] = try await persistence.load(objects: Self.conversationsJSON)
            let models: [Model] = try await persistence.load(objects: Self.modelsJSON)
            let preferences: Preferences? = try await persistence.load(object: Self.preferencesJSON)
            
            await MainActor.run {
                self.agents = agents.isEmpty ? self.defaultAgents : agents
                self.conversations = conversations
                self.models = models
                self.preferences = preferences ?? self.preferences
                self.client = OllamaClient(host: self.preferences.host)
            }
        } catch is DecodingError {
            try await deleteAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: Self.agentsJSON, objects: agents)
        try await persistence.save(filename: Self.conversationsJSON, objects: conversations)
        try await persistence.save(filename: Self.modelsJSON, objects: models)
        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
    }
    
    public func deleteAll() async throws {
        try persistence.delete(filename: Self.agentsJSON)
        try persistence.delete(filename: Self.conversationsJSON)
        try persistence.delete(filename: Self.modelsJSON)
        try persistence.delete(filename: Self.preferencesJSON)
        resetAll()
    }
    
    public func resetAll() {
        self.agents = defaultAgents
        self.conversations = []
        self.models = []
        self.preferences = .init()
        self.client = OllamaClient(host: preferences.host)
    }
    
    public func resetAgents() async throws {
        self.agents = defaultAgents
    }
    
    public func resetClients() {
        self.client = OllamaClient(host: preferences.host)
    }
    
    private var defaultAgents: [Agent] =
        [
            .assistant,
            .vent,
            .learn,
            .brainstorm,
            .advice,
            .anxious,
            .philisophical,
            .discover,
            .coach,
            .journal,
        ]

    // Encoders
    
    private func encode(messages: [Message]) -> [OllamaKit.Message] {
        messages.map {
            OllamaKit.Message(role: encode(role: $0.role), content: $0.content)
        }
    }
    
    private func encode(role: Message.Role) -> OllamaKit.Message.Role {
        switch role {
        case .system:
            return .system
        case .assistant:
            return .assistant
        case .user:
            return .user
        }
    }

    // Previews
    
    public static var preview: Store = {
        let store = Store.shared
        store.resetAll()
        
        store.models = [
            Model.preview,
            .init(
                name: "llama2:7b-chat", 
                size: 0,
                digest: "",
                license: "",
                modelfile: "",
                parameters: "",
                template: "",
                system: ""
            ),
            .init(
                name: "codellama:34b", 
                size: 0,
                digest: "",
                license: "",
                modelfile: "",
                parameters: "",
                template: "",
                system: ""
            ),
        ]
        
        let conversation = Conversation.preview
        store.conversations = [conversation]
        return store
    }()
}
