import Foundation
import SharedKit
import GenKit

public struct Conversation: Codable, Identifiable {
    public var id: String
    public var messages: [Message]
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case none
    }
    
    public init(id: String = .id, messages: [Message] = [], state: State = .none) {
        self.id = id
        self.messages = messages
        self.state = state
        self.state = .none
        self.created = .now
        self.modified = .now
    }
}

extension Conversation: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
    
    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension Conversation {
    
    public static var preview: Self =
        .init(messages: Agent.preview.messages)
}
