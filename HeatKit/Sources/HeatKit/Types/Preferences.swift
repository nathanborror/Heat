import Foundation
import GenKit
import SharedKit

public struct Preferences: Codable {
    
    public var service: Service
    public var model: String?
    public var defaultTemplateID: String?
    
    public enum Service: Codable, Identifiable {
        case openai(String?)
        case ollama(URL?)
        case mistral(String?)
        case perplexity(String?)
        
        public var id: String { title.lowercased() }
        
        public var title: String {
            switch self {
            case .ollama: "Ollama"
            case .openai: "OpenAI"
            case .mistral: "Mistral"
            case .perplexity: "Perplexity"
            }
        }
    }
    
    public init(service: Service, model: String? = nil, defaultTemplateID: String? = nil) {
        self.service = service
        self.model = model
        self.defaultTemplateID = defaultTemplateID
    }
}
