import Foundation
import SharedKit
import GenKit

public struct Config: Codable, Sendable {
    public var services: [Service]
    public var metadata: [String: Value]

    public init() {
        self.services = Defaults.services
        self.metadata = [:]
    }

    func apply(_ config: Config) -> Config {
        var existing = self
        existing.services = config.services
        existing.metadata = config.metadata
        return existing
    }
}

// MARK: - Personalization

extension Config {

    public var userName: String? {
        set { metadata["userName"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userName"]?.stringValue }
    }

    public var userLocation: String? {
        set { metadata["userLocation"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userLocation"]?.stringValue }
    }

    public var userBiography: String? {
        set { metadata["userBiography"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userBiography"]?.stringValue }
    }
}

// MARK: - Service Defaults

extension Config {

    public var serviceChatDefault: String? {
        set { metadata["serviceChatDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceChatDefault"]?.stringValue }
    }

    public var serviceImageDefault: String? {
        set { metadata["serviceImageDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceImageDefault"]?.stringValue }
    }

    public var serviceEmbeddingDefault: String? {
        set { metadata["serviceEmbeddingDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceEmbeddingDefault"]?.stringValue }
    }

    public var serviceTranscriptionDefault: String? {
        set { metadata["serviceTranscriptionDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceTranscriptionDefault"]?.stringValue }
    }

    public var serviceSpeechDefault: String? {
        set { metadata["serviceSpeechDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceSpeechDefault"]?.stringValue }
    }

    public var serviceSummarizationDefault: String? {
        set { metadata["serviceSummarizationDefault"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["serviceSummarizationDefault"]?.stringValue }
    }
}
