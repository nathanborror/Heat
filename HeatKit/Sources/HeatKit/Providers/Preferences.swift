import Foundation
import SharedKit
import GenKit
import OSLog

private let logger = Logger(subsystem: "Preferences", category: "Kit")

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

actor PreferencesStore {
    private var preferences: Preferences = .init()
    
    func save(_ preferences: Preferences) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(preferences)
        try data.write(to: self.dataURL, options: [.atomic])
        self.preferences = preferences
    }
    
    func load() throws -> Preferences {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        preferences = try decoder.decode(Preferences.self, from: data)
        return preferences
    }
    
    private var dataURL: URL {
        get throws {
            let dir = URL.documentsDirectory.appending(path: ".app", directoryHint: .isDirectory)
            if !FileManager.default.fileExists(atPath: dir.relativeString) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir.appendingPathComponent("preferences", conformingTo: .propertyList)
        }
    }
}

actor ServicesStore {
    private var services: [Service] = Defaults.services
    
    func save(_ services: [Service]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(services)
        try data.write(to: self.dataURL, options: [.atomic])
        self.services = services
    }
    
    func load() throws -> [Service] {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        services = try decoder.decode([Service].self, from: data)
        return services
    }
    
    private var dataURL: URL {
        get throws {
            let dir = URL.documentsDirectory.appending(path: ".app", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent("services", conformingTo: .propertyList)
        }
    }
}

@MainActor
@Observable
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
    
    public func get(serviceID: Service.ServiceID?) throws -> Service {
        guard let service = services.first(where: { $0.id == serviceID }) else {
            throw PreferencesProviderError.serviceNotFound
        }
        return service
    }
    
    public func get(modelID: Model.ID?, serviceID: Service.ServiceID?) throws -> Model {
        let service = try get(serviceID: serviceID)
        guard let model = service.models.first(where: { $0.id == modelID }) else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func upsert(_ preferences: Preferences) async throws {
        self.preferences = preferences
        try await save()
    }
    
    public func upsert(service: Service) async throws {
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
        try await save()
    }
    
    public func upsert(token: String, serviceID: Service.ServiceID) async throws {
        var service = try get(serviceID: serviceID)
        service.token = token
        try await upsert(service: service)
        try await initialize(serviceID: serviceID)
    }
    
    public func upsert(models: [Model], serviceID: Service.ServiceID) async throws {
        var service = try get(serviceID: serviceID)
        service.models = models
        try await upsert(service: service)
    }
    
    public func upsert(status: Service.Status, serviceID: Service.ServiceID) async throws {
        var service = try get(serviceID: serviceID)
        service.status = status
        try await upsert(service: service)
    }
    
    public func initialize(serviceID: Service.ServiceID) async throws {
        let service = try get(serviceID: serviceID)
        do {
            let client = service.modelService()
            let models = try await client.models()
            try await upsert(models: models, serviceID: service.id)
            try await upsert(status: .ready, serviceID: service.id)
        } catch {
            logger.error("Service error (\(service.name)): \(error)")
            try await upsert(status: .unknown, serviceID: service.id)
        }
    }
    
    public func initializeServices() async throws {
        for service in services {
            try await initialize(serviceID: service.id)
        }
    }
    
    public func reset() async throws {
        logger.debug("Resetting preferences...")
        self.preferences = .init()
        self.services = Defaults.services
        try await save()
    }
    
    public func flush() async throws {
        try await save()
    }
    
    // MARK: - Service Preferences
    
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
    
    // MARK: - Model Preferences
    
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
    
    // MARK: - Private
    
    private let preferencesStore = PreferencesStore()
    private let servicesStore = ServicesStore()
    
    private init() {
        Task {
            try await load()
            try await initializeServices()
        }
    }
    
    private func load() async throws {
        do {
            preferences = try await preferencesStore.load()
            services = try await servicesStore.load()
            statusCheck()
        } catch {
            logger.error("Failed to load preferences: \(error)")
            try await reset()
        }
        ping()
    }
    
    private func save() async throws {
        try await preferencesStore.save(preferences)
        try await servicesStore.save(services)
        statusCheck()
        ping()
    }
    
    private func ping() {
        updated = .now
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

enum PreferencesProviderError: Error {
    case serviceNotFound
    case modelNotFound
}
