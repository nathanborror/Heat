import Foundation
import SharedKit
import GenKit

public struct Preferences: Codable, Hashable, Sendable {
    public var defaultAgentID: String? = Constants.defaultAgent.id
    public var shouldStream = true
    public var debug = false
    public var preferred: Services = .init()
    
    public struct Services: Codable, Hashable, Sendable {
        public var chatServiceID: Service.ServiceID? = nil
        public var imageServiceID: Service.ServiceID? = nil
        public var embeddingServiceID: Service.ServiceID? = nil
        public var transcriptionServiceID: Service.ServiceID? = nil
        public var toolServiceID: Service.ServiceID? = nil
        public var visionServiceID: Service.ServiceID? = nil
        public var speechServiceID: Service.ServiceID? = nil
        public var summarizationServiceID: Service.ServiceID? = nil
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
            try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
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
    
    public func reset() async throws {
        self.preferences = .init()
        self.services = Constants.defaultServices
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
    
    public func preferredToolService() throws -> ToolService {
        let service = try get(serviceID: preferences.preferred.toolServiceID)
        return try service.toolService()
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
    
    public func preferredChatModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.chatServiceID)
        guard let model = service.preferredChatModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredImageModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.imageServiceID)
        guard let model = service.preferredImageModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredEmbeddingModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.embeddingServiceID)
        guard let model = service.preferredEmbeddingModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredTranscriptionModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.transcriptionServiceID)
        guard let model = service.preferredTranscriptionModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredToolModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.toolServiceID)
        guard let model = service.preferredChatModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredVisionModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.visionServiceID)
        guard let model = service.preferredVisionModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredSpeechModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.speechServiceID)
        guard let model = service.preferredSpeechModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    public func preferredSummarizationModel() throws -> String {
        let service = try get(serviceID: preferences.preferred.summarizationServiceID)
        guard let model = service.preferredSummarizationModel else {
            throw PreferencesProviderError.modelNotFound
        }
        return model
    }
    
    // MARK: - Private
    
    private let preferencesStore = PreferencesStore()
    private let servicesStore = ServicesStore()
    
    private init() {
        Task {
            if BundleVersion.shared.isBundleVersionNew() {
                try await reset()
            } else {
                try await load()
            }
        }
    }
    
    private func load() async throws {
        self.preferences = try await preferencesStore.load()
        self.services = try await servicesStore.load()
        
        if services.isEmpty {
            try await reset()
        }
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
