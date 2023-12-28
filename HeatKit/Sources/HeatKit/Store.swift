import Foundation
import OSLog
import Observation
import GenKit
import SharedKit

private let logger = Logger(subsystem: "Store", category: "HeatKit")

@Observable
public final class Store {
    
    public static let shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var agents: [Agent]
    public private(set) var conversations: [Conversation]
    public private(set) var models: [Model]
    public var preferences: Preferences
    
    private var persistence: Persistence
    
    init(persistence: Persistence) {
        self.agents = []
        self.conversations = []
        self.models = []
        
        let prefs = Preferences()
        self.preferences = prefs
        
        self.persistence = persistence
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
    
    public func upsert(models: [Model]) {
        self.models = models
    }
    
    public func upsert(agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var agent = agent
            agent.modified = .now
            agents[index] = agent
        } else {
            agents.insert(agent, at: 0)
        }
    }
    
    public func upsert(conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var existing = conversations[index]
            existing.messages = conversation.messages
            existing.state = conversation.state
            existing.modified = .now
            conversations[index] = existing
        } else {
            conversations.insert(conversation, at: 0)
        }
    }
    
    public func upsert(messages: [Message], conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        conversation.messages = messages
        upsert(conversation: conversation)
    }
    
    public func upsert(message: Message, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            let existing = conversation.messages[index].apply(message)
            conversation.messages[index] = existing
        } else {
            conversation.messages.append(message)
        }
        upsert(conversation: conversation)
    }
    
    public func upsert(preferences: Preferences) {
        var preferences = preferences
        preferences.modified = .now
        self.preferences = preferences
    }
    
    public func set(state: Conversation.State, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else { return }
        conversation.state = state
        upsert(conversation: conversation)
    }
    
    public func delete(conversation: Conversation) {
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
            }
        } catch is DecodingError {
            try deleteAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: Self.agentsJSON, objects: agents)
        try await persistence.save(filename: Self.conversationsJSON, objects: conversations)
        try await persistence.save(filename: Self.modelsJSON, objects: models)
        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
    }
    
    public func deleteAll() throws {
        try persistence.delete(filename: Self.agentsJSON)
        try persistence.delete(filename: Self.conversationsJSON)
        try persistence.delete(filename: Self.modelsJSON)
        try persistence.delete(filename: Self.preferencesJSON)
        resetAll()
    }
    
    public func resetAll() {
        self.conversations = []
        self.models = []
        self.preferences = .init()
        self.resetAgents()
    }
    
    public func resetAgents() {
        self.agents = defaultAgents
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

public enum StoreError: LocalizedError {
    case missingAgent
    case missingModel
    case missingHost
    
    public var errorDescription: String? {
        switch self {
        case .missingAgent:
            "Missing agent"
        case .missingModel:
            "Missing model"
        case .missingHost:
            "Missing host"
        }
    }
}
