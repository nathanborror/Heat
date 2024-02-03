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

        self.preferredChatServiceID = Constants.defaultChatServiceID
        self.preferredImageServiceID = Constants.defaultImageServiceID
        self.preferredEmbeddingServiceID = Constants.defaultTranscriptionServiceID
        self.preferredTranscriptionServiceID = Constants.defaultTranscriptionServiceID
        
        self.services = Constants.defaultServices
    }
}
