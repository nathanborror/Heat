import Foundation
import GenKit
import SharedKit

public struct Preferences: Codable {
    
    public var service: Service
    public var host: URL?
    public var token: String?
    public var model: String?
    public var defaultAgentID: String?
    
    public enum Service: String, Codable, Identifiable, CaseIterable {
        case openai
        case ollama
        
        public var id: String { rawValue }
        public var title: String {
            switch self {
            case .ollama: "Ollama"
            case .openai: "OpenAI"
            }
        }
    }
    
    public init(service: Service = .ollama, host: URL? = nil, token: String? = nil, model: String? = nil,
                defaultAgentID: String? = nil) {
        self.service = service
        self.host = host
        self.token = token
        self.model = model
        self.defaultAgentID = defaultAgentID
    }
}
