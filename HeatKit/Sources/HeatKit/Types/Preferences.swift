import Foundation
import GenKit

public struct Preferences: Codable {
    
    public var services: [Service]
    
    public var defaultTemplateID: String?
    
    public var preferredChatServiceID: String?
    public var preferredImageServiceID: String?
    public var preferredEmbeddingServiceID: String?
    public var preferredTranscriptionServiceID: String?
    
    public init() {
        self.services = []
        
        self.defaultTemplateID = nil

        self.services = Constants.defaultServices
    }
}
