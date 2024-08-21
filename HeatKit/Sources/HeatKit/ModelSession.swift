import Foundation
import OSLog
import SharedKit
import GenKit

public struct ModelRequest {
    public let service: Service
    public let model: Model
    
    public private(set) var messages: [Message] = []
    public private(set) var tools: [Tool] = []
    public private(set) var memories: [String] = []
    
    public init(service: Service, model: Model, messages: [Message], memories: [String] = []) {
        self.service = service
        self.model = model
        self.messages = messages
        self.memories = memories
    }
    
    public mutating func with(messages: [Message]) {
        self.messages = messages
    }
    
    public mutating func with(tools: [Tool]) {
        self.tools = tools
    }
    
    public mutating func with(memories: [String]) {
        self.memories = memories
    }
}

public class ModelSession {
    public static let shared = ModelSession()
    
    public func chatCompletionStream(_ request: ModelRequest) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { continuation in
        }
    }
    
    public func chatCompletion(_ request: ModelRequest) async throws -> [Message] {
        return []
    }
}

/* Sketchpad

var req = ModelRequest(service, model)
req.with(messages: messages)
req.with(tools: tools)
req.with(memory: memory)

// Example streaming request
let stream = ModelSession.shared.chatCompletionStream(req)
for try await message in stream { message in
    // Handle message
}

// Update request messages with new history
req.replace(messages: resp.messages)

// Example non-streaming request
let resp = await ModelSession.shared.chatCompletion(req)

*/
