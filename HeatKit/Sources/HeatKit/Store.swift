import Foundation
import Observation
import SharedKit
import GenKit
import OSLog

private let logger = Logger(subsystem: "Store", category: "HeatKit")

@Observable
public final class Store {
    
    public static var shared = Store(persistence: DiskPersistence.shared)
    
    public var agents: [Agent] = []
    public var conversations: [Conversation] = []
    public var tools: [Tool] = []
    public var preferences: Preferences = .init()
    
    private let persistence: Persistence
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    // MARK: - Getters
    
    public func get(agentID: String?) -> Agent? {
        agents.first(where: { $0.id == agentID })
    }
    
    public func get(conversationID: String?) -> Conversation? {
        conversations.first(where: { $0.id == conversationID })
    }
    
    public func get(messageID: String, conversationID: String?) -> Message? {
        get(conversationID: conversationID)?.messages.first(where: { $0.id == messageID })
    }
    
    public func get(tool name: String?) -> Tool? {
        tools.first(where: { $0.function.name == name })
    }
    
    public func get(serviceID: String?) -> Service? {
        preferences.services.first(where: { $0.id == serviceID })
    }
    
    // MARK: - Creators
    
    public func createConversation(agent: Agent, state: Conversation.State = .none) -> Conversation {
        var conversation = Conversation(messages: agent.instructions, state: state)
        
        // Append user profile if it exists
        if let instructions = preferences.instructions {
            let message = Message(kind: .instruction, role: .user, content: instructions)
            conversation.messages.append(message)
        }
        return conversation
    }
    
    // MARK: - Upsert
    
    public func upsert(agent: Agent) {
        if let index = agents.firstIndex(where: { $0.id == agent.id }) {
            var existing = agents[index]
            existing.apply(agent: agent)
            agents[index] = existing
        } else {
            agents.insert(agent, at: 0)
        }
    }
    
    public func upsert(conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var existing = conversations[index]
            existing.apply(conversation: conversation)
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
            var existing = conversation.messages[index]
            existing = existing.apply(message)
            conversation.messages[index] = existing
        } else {
            conversation.messages.append(message)
        }
        upsert(conversation: conversation)
    }
    
    public func upsert(preferences: Preferences) {
        self.preferences = preferences
    }
    
    public func upsert(service: Service) {
        if let index = preferences.services.firstIndex(where: { $0.id == service.id }) {
            preferences.services[index] = service
        } else {
            preferences.services.append(service)
        }
    }
    
    // MARK: - Deletion
    
    public func delete(agentID: String?) {
        agents.removeAll(where: { $0.id == agentID })
    }
    
    public func delete(conversationID: String?) {
        conversations.removeAll(where: { $0.id == conversationID })
    }
    
    // MARK: - Service Preferences
    
    public func preferredChatService() throws -> ChatService {
        guard let service = get(serviceID: preferences.preferredChatServiceID) else {
            throw HeatKitError.missingService
        }
        switch service.id {
        case "openai":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return OpenAIService(configuration: .init(token: token))
        case "mistral":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return MistralService(configuration: .init(token: token))
        case "perplexity":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return PerplexityService(configuration: .init(token: token))
        case "ollama":
            guard let host = service.host else {
                throw HeatKitError.missingServiceHost
            }
            return OllamaService(configuration: .init(host: host))
        default:
            throw HeatKitError.missingService
        }
    }
    
    public func preferredImageService() throws -> ImageService {
        guard let service = get(serviceID: preferences.preferredImageServiceID) else {
            throw HeatKitError.missingService
        }
        switch service.id {
        case "openai":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return OpenAIService(configuration: .init(token: token))
        default:
            throw HeatKitError.missingService
        }
    }
    
    public func preferredEmbeddingService() throws -> EmbeddingService {
        guard let service = get(serviceID: preferences.preferredEmbeddingServiceID) else {
            throw HeatKitError.missingService
        }
        switch service.id {
        case "openai":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return OpenAIService(configuration: .init(token: token))
        case "mistral":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return MistralService(configuration: .init(token: token))
        case "ollama":
            guard let host = service.host else {
                throw HeatKitError.missingServiceHost
            }
            return OllamaService(configuration: .init(host: host))
        default:
            throw HeatKitError.missingService
        }
    }
    
    public func preferredTranscriptionService() throws -> TranscriptionService {
        guard let service = get(serviceID: preferences.preferredTranscriptionServiceID) else {
            throw HeatKitError.missingService
        }
        switch service.id {
        case "openai":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return OpenAIService(configuration: .init(token: token))
        default:
            throw HeatKitError.missingService
        }
    }
    
    public func preferredVisionService() throws -> VisionService {
        guard let service = get(serviceID: preferences.preferredVisionServiceID) else {
            throw HeatKitError.missingService
        }
        switch service.id {
        case "openai":
            guard let token = service.token else {
                throw HeatKitError.missingServiceToken
            }
            return OpenAIService(configuration: .init(token: token))
        case "ollama":
            guard let host = service.host else {
                throw HeatKitError.missingServiceHost
            }
            return OllamaService(configuration: .init(host: host))
        default:
            throw HeatKitError.missingService
        }
    }
    
    // MARK: - Model Preferences
    
    public func preferredChatModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredChatServiceID),
              let model = service.preferredChatModel else {
            throw HeatKitError.missingServiceModel
        }
        return model
    }
    
    public func preferredImageModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredImageServiceID),
              let model = service.preferredImageModel else {
            throw HeatKitError.missingServiceModel
        }
        return model
    }
    
    public func preferredEmbeddingModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredEmbeddingServiceID),
              let model = service.preferredEmbeddingModel else {
            throw HeatKitError.missingServiceModel
        }
        return model
    }
    
    public func preferredTranscriptionModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredTranscriptionServiceID),
              let model = service.preferredTranscriptionModel else {
            throw HeatKitError.missingServiceModel
        }
        return model
    }
    
    public func preferredVisionModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredVisionServiceID),
              let model = service.preferredVisionModel else {
            throw HeatKitError.missingServiceModel
        }
        return model
    }
    
    // MARK: - Persistence
    
    static private var agentsJSON = "agents.json"
    static private var conversationsJSON = "conversations.json"
    static private var preferencesJSON = "preferences.json"
    
    public func restore() async throws {
        do {
            let agents: [Agent] = try await persistence.load(objects: Self.agentsJSON)
            let conversations: [Conversation] = try await persistence.load(objects: Self.conversationsJSON)
            let preferences: Preferences? = try await persistence.load(object: Self.preferencesJSON)
            
            await MainActor.run {
                self.agents = agents
                self.conversations = conversations
                self.preferences = preferences ?? self.preferences
            }
            
            if self.agents.isEmpty {
                try resetAgents()
            }
        } catch {
            logger.warning("failed to restore, resetting")
            try resetAll()
        }
        
        logger.info("Persistence: data restored")
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: Self.agentsJSON, objects: agents)
        try await persistence.save(filename: Self.conversationsJSON, objects: conversations)
        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
        
        logger.info("Persistence: data saved")
    }
    
    public func deleteAll() {
        try? persistence.delete(filename: Self.agentsJSON)
        try? persistence.delete(filename: Self.conversationsJSON)
        try? persistence.delete(filename: Self.preferencesJSON)
        try? resetAll()
    }
    
    public func resetAll() throws {
        self.conversations = []
        self.preferences = .init()
        try self.resetAgents()
    }
    
    public func resetAgents() throws {
        self.agents = Constants.defaultAgents
        self.preferences.defaultAgentID = Constants.defaultAgentID
    }
    
    // MARK: - Preview
    
    public static var preview: Store = {
        let store = Store(persistence: MemoryPersistence.shared)
        store.agents = [.preview]
        store.conversations = [.preview]
        return store
    }()
}
