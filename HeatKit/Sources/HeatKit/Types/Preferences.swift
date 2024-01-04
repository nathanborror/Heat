import Foundation
import GenKit
import SharedKit

public struct Preferences: Codable {
    
    public var service: Service
    public var host: URL?
    public var token: String?
    public var model: String?
    public var defaultTemplateID: String?
    
    public enum Service: String, Codable, Identifiable, CaseIterable {
        case openai
        case ollama
        case mistral
        
        public var id: String { rawValue }
        public var title: String {
            switch self {
            case .ollama: "Ollama"
            case .openai: "OpenAI"
            case .mistral: "Mistral"
            }
        }
    }
    
    public init(service: Service = .ollama, host: URL? = nil, token: String? = nil, model: String? = nil,
                defaultTemplateID: String? = nil) {
        self.service = service
        self.host = host
        self.token = token
        self.model = model
        self.defaultTemplateID = defaultTemplateID
    }
}
