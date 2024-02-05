import Foundation

public enum HeatKitError: LocalizedError, Equatable {
    case failedGenerateResponse
    case failedtoolDecoding
    case missingResource
    case missingService
    case missingServiceModel
    case missingServiceToken
    case missingServiceHost
    case missingConversation
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .failedGenerateResponse:
            "Failed to generate response"
        case .failedtoolDecoding:
            "Failed to decode tool"
        case .missingResource:
            "Missing resource"
        case .missingService:
            "Missing service"
        case .missingServiceModel:
            "Missing service model"
        case .missingServiceToken:
            "Missing service token"
        case .missingServiceHost:
            "Missing service host"
        case .missingConversation:
            "Missing conversation"
        case .unknown:
            "Unknown"
        }
    }
    
    public var recoverySuggestion: String {
        switch self {
        case .failedGenerateResponse:
            "Try again."
        case .failedtoolDecoding:
            "Try again"
        case .missingResource:
            "Try again"
        case .missingService:
            "Pick a service in preferences."
        case .missingServiceModel:
            "Pick a model for the specific service in preferences."
        case .missingServiceToken:
            "The service requires a token to operate."
        case .missingServiceHost:
            "The service requires a host URL to operate."
        case .missingConversation:
            "Try again"
        case .unknown:
            "Try again"
        }
    }
}
