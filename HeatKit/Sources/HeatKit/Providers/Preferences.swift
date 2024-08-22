import Foundation
import GenKit

public struct Preferences: Codable {
    
    public var defaultAgentID: String?
    public var shouldStream: Bool
    public var debug: Bool
    
    public var preferredChatServiceID: Service.ServiceID?
    public var preferredImageServiceID: Service.ServiceID?
    public var preferredEmbeddingServiceID: Service.ServiceID?
    public var preferredTranscriptionServiceID: Service.ServiceID?
    public var preferredToolServiceID: Service.ServiceID?
    public var preferredVisionServiceID: Service.ServiceID?
    public var preferredSpeechServiceID: Service.ServiceID?
    public var preferredSummarizationServiceID: Service.ServiceID?
    
    public init() {
        self.defaultAgentID = Constants.defaultAgent.id
        self.shouldStream = true
        self.debug = false

        self.preferredChatServiceID = Constants.defaultChatServiceID
        self.preferredImageServiceID = Constants.defaultImageServiceID
        self.preferredEmbeddingServiceID = Constants.defaultTranscriptionServiceID
        self.preferredTranscriptionServiceID = Constants.defaultTranscriptionServiceID
        self.preferredToolServiceID = Constants.defaultToolServiceID
        self.preferredVisionServiceID = Constants.defaultVisionServiceID
        self.preferredSpeechServiceID = Constants.defaultSpeechServiceID
        self.preferredSummarizationServiceID = Constants.defaultSummarizationServiceID
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
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("PreferencesData.plist")
        }
    }
}

actor ServicesStore {
    private var services: [Service] = Constants.defaultServices
    
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
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("ServicesData.plist")
        }
    }
}

@MainActor
@Observable
public final class PreferencesProvider {
    public static let shared = PreferencesProvider()
    
    public private(set) var preferences: Preferences = .init()
    public private(set) var services: [Service] = []
    
    public func get(serviceID: Service.ServiceID?) throws -> Service {
        guard let service = services.first(where: { $0.id == serviceID }) else {
            throw PreferencesProviderError.serviceNotFound
        }
        return service
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
    
    public func delete() async throws {
        self.preferences = .init()
        self.services = Constants.defaultServices
        try await save()
    }
    
    // MARK: - Service Preferences
    
    public func preferredChatService() throws -> ChatService {
        let service = try get(serviceID: preferences.preferredChatServiceID)
        return try service.chatService()
    }
    
    public func preferredImageService() throws -> ImageService {
        let service = try get(serviceID: preferences.preferredImageServiceID)
        return try service.imageService()
    }
    
    public func preferredEmbeddingService() throws -> EmbeddingService {
        let service = try get(serviceID: preferences.preferredEmbeddingServiceID)
        return try service.embeddingService()
    }
    
    public func preferredTranscriptionService() throws -> TranscriptionService {
        let service = try get(serviceID: preferences.preferredTranscriptionServiceID)
        return try service.transcriptionService()
    }
    
    public func preferredToolService() throws -> ToolService {
        let service = try get(serviceID: preferences.preferredToolServiceID)
        return try service.toolService()
    }
    
    public func preferredVisionService() throws -> VisionService {
        let service = try get(serviceID: preferences.preferredVisionServiceID)
        return try service.visionService()
    }
    
    public func preferredSpeechService() throws -> SpeechService {
        let service = try get(serviceID: preferences.preferredSpeechServiceID)
        return try service.speechService()
    }
    
    public func preferredSummarizationService() throws -> ChatService {
        let service = try get(serviceID: preferences.preferredSummarizationServiceID)
        return try service.summarizationService()
    }
    
    // MARK: - Model Preferences
    
    public func preferredChatModel() throws -> String {
        let service = try get(serviceID: preferences.preferredChatServiceID)
        guard let model = service.preferredChatModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredImageModel() throws -> String {
        let service = try get(serviceID: preferences.preferredImageServiceID)
        guard let model = service.preferredImageModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredEmbeddingModel() throws -> String {
        let service = try get(serviceID: preferences.preferredEmbeddingServiceID)
        guard let model = service.preferredEmbeddingModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredTranscriptionModel() throws -> String {
        let service = try get(serviceID: preferences.preferredTranscriptionServiceID)
        guard let model = service.preferredTranscriptionModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredToolModel() throws -> String {
        let service = try get(serviceID: preferences.preferredToolServiceID)
        guard let model = service.preferredChatModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredVisionModel() throws -> String {
        let service = try get(serviceID: preferences.preferredVisionServiceID)
        guard let model = service.preferredVisionModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredSpeechModel() throws -> String {
        let service = try get(serviceID: preferences.preferredSpeechServiceID)
        guard let model = service.preferredSpeechModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredSummarizationModel() throws -> String {
        let service = try get(serviceID: preferences.preferredSummarizationServiceID)
        guard let model = service.preferredSummarizationModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    // MARK: - Private
    
    private let preferencesStore = PreferencesStore()
    private let servicesStore = ServicesStore()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        self.preferences = try await preferencesStore.load()
        self.services = try await servicesStore.load()
    }
    
    private func save() async throws {
        try await preferencesStore.save(preferences)
        try await servicesStore.save(services)
    }
}

enum PreferencesProviderError: Error {
    case serviceNotFound
    case modelNotFound
}
