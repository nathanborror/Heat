import Foundation
import GenKit

public struct Preferences: Codable {
    
    public var services: [Service]
    public var instructions: String?
    
    public var defaultAgentID: String?
    
    public var preferredChatServiceID: String?
    public var preferredImageServiceID: String?
    public var preferredEmbeddingServiceID: String?
    public var preferredTranscriptionServiceID: String?
    
    public init() {
        self.services = []
        self.instructions = nil
        
        self.defaultAgentID = nil

        self.preferredChatServiceID = nil //Constants.defaultChatServiceID
        self.preferredImageServiceID = nil //Constants.defaultImageServiceID
        self.preferredEmbeddingServiceID = nil //Constants.defaultTranscriptionServiceID
        self.preferredTranscriptionServiceID = nil //Constants.defaultTranscriptionServiceID
        
        self.services = Constants.defaultServices
    }
}
