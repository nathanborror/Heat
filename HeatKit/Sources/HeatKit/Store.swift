import Foundation
import Observation
import SharedKit
import GenKit
import OSLog
import Yams

private let logger = Logger(subsystem: "Store", category: "HeatKit")

@Observable
public final class Store {
    
    public static var shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var agents: [Agent] = []
    public private(set) var conversations: [Conversation] = []
    public private(set) var tools: Set<Tool> = []
    public var preferences: Preferences = .init()
    
    private let persistence: Persistence
    
    public var isChatAvailable: Bool {
        preferences.preferredChatServiceID != nil
    }
    
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
    
    public func get(tools: Set<String>) -> Set<Tool> {
        Set(tools.compactMap { get(tool: $0) })
    }
    
    public func get(serviceID: Service.ServiceID?) -> Service? {
        preferences.services.first(where: { $0.id == serviceID })
    }
    
    // MARK: - Creators
    
    public func createConversation(agent: Agent, state: Conversation.State = .none) -> Conversation {
        let instructions = agent.instructions.map {
            var message = $0
            message.content = message.content?.apply(context: [
                "datetime": Date.now.format(as: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS")
            ])
            return message
        }
        let tools = get(tools: agent.toolIDs)
        var conversation = Conversation(messages: instructions, tools: tools, state: state)
        
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
        for message in messages {
            upsert(message: message, conversationID: conversationID)
        }
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
    
    public func upsert(title: String, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        conversation.title = title
        upsert(conversation: conversation)
    }
    
    public func upsert(suggestions: [String], conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        conversation.suggestions = suggestions
        upsert(conversation: conversation)
    }
    
    public func upsert(state: Conversation.State, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        conversation.state = state
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
    
    // MARK: - Replace
    
    public func replace(message: Message, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else {
            logger.warning("missing conversation")
            return
        }
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            conversation.messages[index] = message
        } else {
            conversation.messages.append(message)
        }
        upsert(conversation: conversation)
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
            throw HeatKitError.missingService("Chat")
        }
        return try service.chatService()
    }
    
    public func preferredImageService() throws -> ImageService {
        guard let service = get(serviceID: preferences.preferredImageServiceID) else {
            throw HeatKitError.missingService("Image")
        }
        return try service.imageService()
    }
    
    public func preferredEmbeddingService() throws -> EmbeddingService {
        guard let service = get(serviceID: preferences.preferredEmbeddingServiceID) else {
            throw HeatKitError.missingService("Embedding")
        }
        return try service.embeddingService()
    }
    
    public func preferredTranscriptionService() throws -> TranscriptionService {
        guard let service = get(serviceID: preferences.preferredTranscriptionServiceID) else {
            throw HeatKitError.missingService("Transcription")
        }
        return try service.transcriptionService()
    }
    
    public func preferredToolService() throws -> ToolService {
        guard let service = get(serviceID: preferences.preferredToolServiceID) else {
            throw HeatKitError.missingService("Tool")
        }
        return try service.toolService()
    }
    
    public func preferredVisionService() throws -> VisionService {
        guard let service = get(serviceID: preferences.preferredVisionServiceID) else {
            throw HeatKitError.missingService("Vision")
        }
        return try service.visionService()
    }
    
    public func preferredSpeechService() throws -> SpeechService {
        guard let service = get(serviceID: preferences.preferredSpeechServiceID) else {
            throw HeatKitError.missingService("Speech")
        }
        return try service.speechService()
    }
    
    public func preferredSummarizationService() throws -> ChatService {
        guard let service = get(serviceID: preferences.preferredSummarizationServiceID) else {
            throw HeatKitError.missingService("Summarization")
        }
        return try service.summarizationService()
    }
    
    // MARK: - Model Preferences
    
    public func preferredChatModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredChatServiceID),
              let model = service.preferredChatModel else {
            throw HeatKitError.missingServiceModel("Chat")
        }
        return model
    }
    
    public func preferredImageModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredImageServiceID),
              let model = service.preferredImageModel else {
            throw HeatKitError.missingServiceModel("Image")
        }
        return model
    }
    
    public func preferredEmbeddingModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredEmbeddingServiceID),
              let model = service.preferredEmbeddingModel else {
            throw HeatKitError.missingServiceModel("Embedding")
        }
        return model
    }
    
    public func preferredTranscriptionModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredTranscriptionServiceID),
              let model = service.preferredTranscriptionModel else {
            throw HeatKitError.missingServiceModel("Transcription")
        }
        return model
    }
    
    public func preferredToolModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredToolServiceID),
              let model = service.preferredChatModel else {
            throw HeatKitError.missingServiceModel("Tool")
        }
        return model
    }
    
    public func preferredVisionModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredVisionServiceID),
              let model = service.preferredVisionModel else {
            throw HeatKitError.missingServiceModel("Vision")
        }
        return model
    }
    
    public func preferredSpeechModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredSpeechServiceID),
              let model = service.preferredSpeechModel else {
            throw HeatKitError.missingServiceModel("Speech")
        }
        return model
    }
    
    public func preferredSummarizationModel() throws -> String {
        guard let service = get(serviceID: preferences.preferredSummarizationServiceID),
              let model = service.preferredSummarizationModel else {
            throw HeatKitError.missingServiceModel("Summarization")
        }
        return model
    }
    
    // MARK: - Persistence
    
    static private var agentsJSON = "agents.json"
    static private var conversationsJSON = "conversations.json"
    static private var preferencesJSON = "preferences.json"
    
    public func restoreAll() async throws {
        do {
            let agents: [Agent] = try await persistence.load(objects: Self.agentsJSON)
            let conversations: [Conversation] = try await persistence.load(objects: Self.conversationsJSON)
            let preferences: Preferences? = try await persistence.load(object: Self.preferencesJSON)
            
            await MainActor.run {
                self.agents = agents
                self.conversations = conversations
                self.preferences = preferences ?? self.preferences
                self.resetTools()
            }
            
            if self.agents.isEmpty {
                try resetAgents()
            }
            logger.info("Persistence: all data restored")
        } catch {
            logger.warning("Persistence: all data failed to restore")
            try resetAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: Self.agentsJSON, objects: agents)
        try await persistence.save(filename: Self.conversationsJSON, objects: conversations)
        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
        logger.info("Persistence: all data saved")
    }
    
    public func deleteAll() throws {
        try persistence.deleteAll()
        try resetAll()
        logger.info("Persistence: all data deleted")
    }
    
    public func resetAll() throws {
        agents = []
        conversations = []
        preferences = .init()
        try resetAgents()
        resetTools()
        logger.info("Persistence: all data reset")
    }
    
    public func resetAgents() throws {
        guard let url = Bundle.module.url(forResource: "agents", withExtension: "yaml") else {
            throw HeatKitError.missingResource
        }
        let data = try Data(contentsOf: url)
        let response = try YAMLDecoder().decode(AgentsResource.self, from: data)
        self.agents = response.agents.map { $0.encode }
        self.preferences.defaultAgentID = Constants.defaultAgentID
    }
    
    public func resetTools() {
        self.tools = [
            .generateImages,
            .generateWebBrowse,
            .searchCalendar,
            .searchWeb,
            .searchFiles,
            .generateMemory,
        ]
    }
    
    // MARK: - Preview
    
    public static var preview: Store = {
        let store = Store(persistence: MemoryPersistence.shared)
        store.agents = [.preview]
        store.conversations = [.preview1, .preview2]
        store.preferences.debug = true
        return store
    }()
}
