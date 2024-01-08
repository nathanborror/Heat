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
        case perplexity
        
        public var id: String { rawValue }
        public var title: String {
            switch self {
            case .ollama: "Ollama"
            case .openai: "OpenAI"
            case .mistral: "Mistral"
            case .perplexity: "Perplexity"
            }
        }
    }
    
    public init(service: Service = .ollama, host: URL? = nil, token: String? = nil, model: String? = nil,
                defaultTemplateID: String? = nil) {
        self.service = service
        self.model = model
        self.defaultTemplateID = defaultTemplateID
    }
}
