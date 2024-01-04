import Foundation
import SharedKit
import GenKit

public struct Conversation: Codable, Identifiable {
    public var id: String
    public var title: String
    public var messages: [Message]
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case none
    }
    
    public init(id: String = .id, title: String = "New Conversation", messages: [Message] = [], state: State = .none) {
        self.id = id
        self.title = title
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
    
    public static var preview: Self = {
        var messages = Template.preview.messages
        messages += [
            .init(role: .assistant, content: """
                I'm here to help you vent, go ahead and share what's on your mind. Is there a specific situation or \
                thing that's been bothering you? I'm here to listen.
                """),
            .init(role: .user, content: """
                It's been an intense year
                """),
            .init(role: .assistant, content: """
                I can imagine it has been a challenging year for many people, with everything that's been happening. \
                If you want to talk about your experiences or things that have been particularly difficult for you, \
                please feel free to share. I'm here to listen.
                """),
            .init(role: .user, content: """
                Just trying to keep up!
                """),
        ]
        return .init(messages: messages)
    }()
}
