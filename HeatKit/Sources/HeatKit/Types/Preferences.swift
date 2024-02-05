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

        self.preferredChatServiceID = nil
        self.preferredImageServiceID = nil
        self.preferredEmbeddingServiceID = nil
        self.preferredTranscriptionServiceID = nil
        
        self.services = Constants.defaultServices
    }
}
