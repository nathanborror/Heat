import Foundation
import SharedKit
import GenKit
import OSLog

private let logger = Logger(subsystem: "Preferences", category: "Providers")

public struct Preferences: Codable, Sendable {
    public var defaultAssistantID: String? = Defaults.assistantDefaultID
    public var defaultVoiceID: String? = nil
    public var shouldStream = true
    public var textRendering: TextRendering = .markdown
    public var debug = false
    public var preferred: Services = .init()

    public struct Services: Codable, Sendable {
        public var chatServiceID: String? = nil
        public var imageServiceID: String? = nil
        public var embeddingServiceID: String? = nil
        public var transcriptionServiceID: String? = nil
        public var speechServiceID: String? = nil
        public var summarizationServiceID: String? = nil
    }

    public enum TextRendering: String, CaseIterable, Codable, Sendable {
        case markdown
        case text
        case attributed
    }

    public static let empty = Preferences()
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
        case needsServiceOnboarding
        case needsPreferredService
    }

    public enum Error: Swift.Error, CustomStringConvertible {
        case serviceNotFound(String?)
        case modelNotFound(String?)
        case persistenceError(String)
        case missingService
        case missingServiceModel

        public var description: String {
            switch self {
            case .serviceNotFound(let id):
                "Service not found: \(id ?? "empty")"
            case .modelNotFound(let id):
                "Service Model not found: \(id ?? "empty")"
            case .persistenceError(let detail):
                "Preferences persistence error: \(detail)"
            case .missingService:
                "Missing service"
            case .missingServiceModel:
                "Missing service model"
            }
        }
    }

    private let store: DataStore<Preferences>
    private let servicesStore: DataStore<[Service]>
    private var storeRestoreTask: Task<Void, Never>?

    private init() {
        self.store = .init(location: ".app/preferences")
        self.servicesStore = .init(location: ".app/services")
        self.storeRestoreTask = Task { await restore() }
    }

    private func restore() async {
        do {
            preferences = try await store.read() ?? .init()
            services = try await servicesStore.read() ?? []
            statusCheck()
        } catch {
            logger.error("[PreferencesProvider] Error restoring: \(error)")

            do {
                try await reset()
            } catch {
                logger.error("[PreferencesProvider] Error resetting: \(error)")
            }
        }
        ping()
    }

    private func save() async throws {
        do {
            try await store.write(preferences)
            try await servicesStore.write(services)
            statusCheck()
            ping()
        } catch {
            throw Error.persistenceError(error.localizedDescription)
        }
    }

    private func ping() {
        updated = .now
    }

    public func ready() async {
        await storeRestoreTask?.value
    }

    private func statusCheck() {
        // Check for chat service support
        if services.filter({ $0.supportsChats }).isEmpty {
            status = .needsServiceOnboarding
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

    public func get(serviceID: String?) throws -> Service {
        guard let service = services.first(where: { $0.id == serviceID }) else {
            throw Error.serviceNotFound(serviceID)
        }
        return service
    }

    public func get(modelID: String?, serviceID: String?) throws -> Model {
        let service = try get(serviceID: serviceID)
        guard let model = service.models.first(where: { $0.id == modelID }) else {
            throw Error.modelNotFound(modelID)
        }
        return model
    }

    public func upsert(_ preferences: Preferences) async throws {
        await ready()
        self.preferences = preferences
        try await save()
    }

    public func upsert(service: Service) async throws {
        await ready()
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
        try await save()
    }

    public func upsert(token: String, serviceID: String) async throws {
        await ready()
        var service = try get(serviceID: serviceID)
        service.token = token
        try await upsert(service: service)
    }

    public func initialize(serviceID: String) async throws {
        await ready()
        var service = try get(serviceID: serviceID)
        do {
            let client = service.modelService()
            service.models = try await client.models()
            service.status = .ready
            try await upsert(service: service)
        } catch {
            logger.error("[PreferencesProvider] Error initializing service: \(error)")

            service.status = .unknown
            try await upsert(service: service)
        }
    }

    public func initializeServices() async throws {
        await ready()
        for service in services {
            if service.id == Service.ServiceID.ollama.rawValue || !service.token.isEmpty {
                try await initialize(serviceID: service.id)
            }
        }
    }

    public func reset() async throws {
        self.preferences = .init()
        self.services = Defaults.services
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

    public func preferredSpeechModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.speechServiceID)
        return try get(modelID: service.preferredSpeechModel, serviceID: service.id)
    }

    public func preferredSummarizationModel() throws -> Model {
        let service = try get(serviceID: preferences.preferred.summarizationServiceID)
        return try get(modelID: service.preferredSummarizationModel, serviceID: service.id)
    }
}
