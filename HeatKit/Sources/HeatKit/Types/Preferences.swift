import Foundation
import GenKit

public struct Preferences: Codable {
    
    public var services: [Service]
    public var instructions: String?
    
    public var defaultAgentID: String?
    
    public var preferredChatServiceID: Service.ServiceID?
    public var preferredImageServiceID: Service.ServiceID?
    public var preferredEmbeddingServiceID: Service.ServiceID?
    public var preferredTranscriptionServiceID: Service.ServiceID?
    public var preferredToolServiceID: Service.ServiceID?
    public var preferredVisionServiceID: Service.ServiceID?
    public var preferredSpeechServiceID: Service.ServiceID?
    public var preferredSummarizationServiceID: Service.ServiceID?
    
    public init() {
        self.services = []
        self.instructions = nil
        
        self.defaultAgentID = nil

        self.preferredChatServiceID = Constants.defaultChatServiceID
        self.preferredImageServiceID = Constants.defaultImageServiceID
        self.preferredEmbeddingServiceID = Constants.defaultTranscriptionServiceID
        self.preferredTranscriptionServiceID = Constants.defaultTranscriptionServiceID
        self.preferredToolServiceID = Constants.defaultToolServiceID
        self.preferredVisionServiceID = Constants.defaultVisionServiceID
        self.preferredSpeechServiceID = Constants.defaultSpeechServiceID
        self.preferredSummarizationServiceID = Constants.defaultSummarizationServiceID
        
        self.services = Constants.defaultServices
    }
}
