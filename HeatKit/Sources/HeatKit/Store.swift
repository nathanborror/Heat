import Foundation
import OSLog
import Observation
import GenKit
import SharedKit

private let logger = Logger(subsystem: "Store", category: "HeatKit")

@Observable
public final class Store {
    
    public static let shared = Store(persistence: DiskPersistence.shared)
    
    public private(set) var templates: [Template]
    public private(set) var conversations: [Conversation]
    public private(set) var models: [Model]
    public var preferences: Preferences
    
    private var persistence: Persistence
    
    init(persistence: Persistence) {
        self.templates = []
        self.conversations = []
        self.models = []
        
        let prefs = Preferences()
        self.preferences = prefs
        
        self.persistence = persistence
    }

    // MARK: - Getters
    
    public func get(modelID: String) -> Model? {
        models.first(where: { $0.id == modelID })
    }
    
    public func get(templateID: String) -> Template? {
        templates.first(where: { $0.id == templateID })
    }
    
    public func get(conversationID: String) -> Conversation? {
        conversations.first(where: { $0.id == conversationID })
    }
    
    public func get(serviceID: String?) -> Service? {
        preferences.services.first(where: { $0.id == serviceID })
    }
    
    // MARK: - Setters
    
    public func set(state: Conversation.State, conversationID: String) {
        guard var conversation = get(conversationID: conversationID) else { return }
        conversation.state = state
        upsert(conversation: conversation)
    }

    // MARK: - Upserts
    
    public func upsert(models: [Model]) {
        self.models = models
    }
    
    public func upsert(template: Template) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            var template = template
            template.modified = .now
            templates[index] = template
        } else {
            templates.insert(template, at: 0)
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
    
    public func delete(template: Template) {
        templates.removeAll(where: { $0.id == template.id })
    }
    
    public func delete(conversation: Conversation) {
        conversations.removeAll(where: { $0.id == conversation.id })
    }
    
    // MARK: - Service Preferences
    
    public func preferredChatService() -> ChatService? {
        guard let service = get(serviceID: preferences.preferredChatServiceID) else { return nil }
        switch service.id {
        case "openai":
            guard let token = service.token else { return nil }
            return OpenAIService(configuration: .init(token: token))
        case "mistral":
            guard let token = service.token else { return nil }
            return MistralService(configuration: .init(token: token))
        case "perplexity":
            guard let token = service.token else { return nil }
            return PerplexityService(configuration: .init(token: token))
        case "ollama":
            guard let host = service.host else { return nil }
            return OllamaService(configuration: .init(host: host))
        default:
            return nil
        }
    }
    
    public func preferredImageService() -> ImageService? {
        guard let service = get(serviceID: preferences.preferredImageServiceID) else { return nil }
        switch service.id {
        case "openai":
            guard let token = service.token else { return nil }
            return OpenAIService(configuration: .init(token: token))
        default:
            return nil
        }
    }
    
    // MARK: - Model Preferences
    
    public func preferredChatModel() -> String? {
        guard let service = get(serviceID: preferences.preferredChatServiceID) else { return nil }
        return service.preferredChatModel
    }
    
    public func preferredImageModel() -> String? {
        guard let service = get(serviceID: preferences.preferredImageServiceID) else { return nil }
        return service.preferredImageModel
    }

    // MARK: - Persistence
    
    static private var templatesJSON = "templates.json"
    static private var conversationsJSON = "conversations.json"
    static private var modelsJSON = "models.json"
    static private var preferencesJSON = "preferences.json"
    
    public func restore() async throws {
        do {
            let templates: [Template] = try await persistence.load(objects: Self.templatesJSON)
            let conversations: [Conversation] = try await persistence.load(objects: Self.conversationsJSON)
            let models: [Model] = try await persistence.load(objects: Self.modelsJSON)
            let preferences: Preferences? = try await persistence.load(object: Self.preferencesJSON)
            
            await MainActor.run {
                self.templates = templates.isEmpty ? self.defaultTemplates : templates
                self.conversations = conversations
                self.models = models
                self.preferences = preferences ?? self.preferences
            }
        } catch is DecodingError {
            try deleteAll()
        }
    }
    
    public func saveAll() async throws {
        try await persistence.save(filename: Self.templatesJSON, objects: templates)
        try await persistence.save(filename: Self.conversationsJSON, objects: conversations)
        try await persistence.save(filename: Self.modelsJSON, objects: models)
        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
    }
    
    public func deleteAll() throws {
        try persistence.delete(filename: Self.templatesJSON)
        try persistence.delete(filename: Self.conversationsJSON)
        try persistence.delete(filename: Self.modelsJSON)
        try persistence.delete(filename: Self.preferencesJSON)
        resetAll()
    }
    
    public func resetAll() {
        self.conversations = []
        self.models = []
        self.preferences = .init()
        self.resetTemplates()
    }
    
    public func resetTemplates() {
        self.templates = defaultTemplates
    }
    
    private var defaultTemplates: [Template] =
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

    // MARK: - Previews
    
    public static var preview: Store = {
        let store = Store.shared
        store.resetAll()
        
        store.models = [
            .init(id: "llama2:7b-chat", owner: ""),
            .init(id: "mixtral:latest", owner: ""),
        ]
        
        let conversation = Conversation.preview
        store.conversations = [conversation]
        return store
    }()
}
