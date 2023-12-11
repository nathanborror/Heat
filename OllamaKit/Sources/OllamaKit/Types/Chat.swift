import Foundation

public struct ChatRequest: Codable {
    public var model: String
    public var messages: [Message]
    public var stream: Bool?
    public var format: String?
    
    public init(model: String, messages: [Message], stream: Bool? = nil, format: String? = nil) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.format = format
    }
}

public struct ChatResponse: Codable {
    public let model: String
    public let createdAt: Date
    public let message: Message?
    public let done: Bool?
    
    public let totalDuration: Int?
    public let loadDuration: Int?
    public let promptEvalCount: Int?
    public let promptEvalDuration: Int?
    public let evalCount: Int?
    public let evalDuration: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case promptEvalDuration = "prompt_eval_duration"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }
}

public struct Message: Codable {
    public var role: Role
    public var content: String
    
    public enum Role: String, Codable {
        case system, assistant, user
    }
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
