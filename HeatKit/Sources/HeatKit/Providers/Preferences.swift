import Foundation
import SharedKit
import GenKit
import OSLog

private let logger = Logger(subsystem: "Preferences", category: "Providers")

public struct Preferences: Codable, Sendable {
    public var defaultAssistantID: String? = Defaults.assistantDefaultID
    public var shouldStream = true
    public var textRendering: TextRendering = .markdown
    public var debug = false
    public var preferred: Services = .init()
    
    public struct Services: Codable, Sendable {
        public var chatServiceID: Service.ServiceID? = nil
        public var imageServiceID: Service.ServiceID? = nil
        public var embeddingServiceID: Service.ServiceID? = nil
        public var transcriptionServiceID: Service.ServiceID? = nil
        public var visionServiceID: Service.ServiceID? = nil
        public var speechServiceID: Service.ServiceID? = nil
        public var summarizationServiceID: Service.ServiceID? = nil
    }
    
    public enum TextRendering: String, CaseIterable, Codable, Sendable {
        case markdown
        case text
        case attributed
    }
}

@MainActor @Observable
public final class PreferencesProvider {
    public static let shared = PreferencesProvider()

    public private(set) var preferences: Preferences = .init()
    public private(set) var services: [Service] = []
    public private(set) var status: Status = .waiting
    public private(set) var updated: Date = .now

    public enum Status {
        case ready
        case waiting
        case needsServiceSetup
        case needsPreferredService
    }

    public enum Error: Swift.Error {
        case serviceNotFound
        case modelNotFound
    }

    private let preferencesStore: PropertyStore<Preferences>
    private let servicesStore: PropertyStore<[Service]>
    private var preferencesInitTask: Task<Void, Swift.Error>?

    private init() {
        self.preferencesStore = .init(location: ".app/preferences")
        self.servicesStore = .init(location: ".app/services")

        self.preferencesInitTask = Task {
            try await load()
        }
    }

    private func load() async throws {
        do {
            preferences = try await preferencesStore.read() ?? .init()
            services = try await servicesStore.read() ?? []
            statusCheck()
        } catch {
            logger.error("[PreferencesProvider] Failed to load — \(error)")
            try await reset()
        }
        ping()
    }

    private func save() async throws {
        try await preferencesStore.write(preferences)
        try await servicesStore.write(services)
        statusCheck()
        ping()
    }

    // Update the `updated` timestamp and may do other things in the future.
    private func ping() {
        updated = .now
    }

    // Ensures cached data has loaded before continuing.
    private func ready() async throws {
        if let task = preferencesInitTask {
            try await task.value
        }
    }

    private func statusCheck() {
        // Check for chat service support
        if services.filter({ $0.supportsChats }).isEmpty {
            status = .needsServiceSetup
            return
        }
        // Check for preferred chat service
        if preferences.preferred.chatServiceID == nil {
            status = .needsPreferredService
            return
        }
        // Minimal services ready to go
        status = .ready
    }
}

extension PreferencesProvider {

    public func get(serviceID: Service.ServiceID?) throws -> Service {
        guard let service = services.first(where: { $0.id == serviceID }) else {
            throw Error.serviceNotFound
        }
        return service
    }

    public func get(modelID: Model.ID?, serviceID: Service.ServiceID?) throws -> Model {
        let service = try get(serviceID: serviceID)
        guard let model = service.models.first(where: { $0.id == modelID }) else {
            throw Error.modelNotFound
        }
        return model
    }

    public func upsert(_ preferences: Preferences) async throws {
        try await ready()
        self.preferences = preferences
        try await save()
    }

    public func upsert(service: Service) async throws {
        try await ready()
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
        try await save()
    }

    public func upsert(token: String, serviceID: Service.ServiceID) async throws {
        try await ready()
        var service = try get(serviceID: serviceID)
        service.token = token
        try await upsert(service: service)
    }

    public func initialize(serviceID: Service.ServiceID) async throws {
        try await ready()
        var service = try get(serviceID: serviceID)
        do {
            let client = service.modelService()
            service.models = try await client.models()
            service.status = .ready
            try await upsert(service: service)
        } catch {
            logger.error("Service error (\(service.name)): \(error)")
            service.status = .unknown
            try await upsert(service: service)
        }
    }

    public func initializeServices() async throws {
        try await ready()
        for service in services {
            if service.id == .ollama || !service.token.isEmpty {
                try await initialize(serviceID: service.id)
            }
        }
    }

    public func reset() async throws {
        try await ready()
        self.preferences = .init()
        self.services = Defaults.services
        try await save()
        logger.debug("[PreferencesProvider] Reset")
    }

    public func flush() async throws {
        try await ready()
        try await save()
    }
}

// MARK: - Service Preferences

extension PreferencesProvider {

    public func preferredChatService() throws -> ChatService {
        let service = try get(serviceID: preferences.preferred.chatServiceID)
        return try service.chatService()
    }

    public func preferredImageService() throws -> ImageService {
        let service = try get(serviceID: preferences.preferred.imageServiceID)
        return try service.imageService()
    }

    public func preferredEmbeddingService() throws -> EmbeddingService {
        let service = try get(serviceID: preferences.preferred.embeddingServiceID)
        return try service.embeddingService()
    }

    public func preferredTranscriptionService() throws -> TranscriptionService {
        let service = try get(serviceID: preferences.preferred.transcriptionServiceID)
        return try service.transcriptionService()
    }

    public func preferredVisionService() throws -> VisionService {
        let service = try get(serviceID: preferences.preferred.visionServiceID)
        return try service.visionService()
    }

    public func preferredSpeechService() throws -> SpeechService {
        let service = try get(serviceID: preferences.preferred.speechServiceID)
        return try service.speechService()
    }

    public func preferredSummarizationService() throws -> ChatService {
        let service = try get(serviceID: preferences.preferred.summarizationServiceID)
        return try service.summarizationService()
    }
}

// MARK: - Model Preferences

extension PreferencesProvider {

    public func preferredChatModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.chatServiceID)
        return try get(modelID: service.preferredChatModel, serviceID: service.id)
    }
    
    public func preferredImageModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.imageServiceID)
        return try get(modelID: service.preferredImageModel, serviceID: service.id)
    }
    
    public func preferredEmbeddingModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.embeddingServiceID)
        return try get(modelID: service.preferredEmbeddingModel, serviceID: service.id)
    }
    
    public func preferredTranscriptionModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.transcriptionServiceID)
        return try get(modelID: service.preferredTranscriptionModel, serviceID: service.id)
    }
    
    public func preferredVisionModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.visionServiceID)
        return try get(modelID: service.preferredVisionModel, serviceID: service.id)
    }
    
    public func preferredSpeechModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.speechServiceID)
        return try get(modelID: service.preferredSpeechModel, serviceID: service.id)
    }
    
    public func preferredSummarizationModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.summarizationServiceID)
        return try get(modelID: service.preferredSummarizationModel, serviceID: service.id)
    }
}
