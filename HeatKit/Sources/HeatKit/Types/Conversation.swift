// A conversation is an interaction between the user and a large language model (LLM). It has a title that helps
// set context for what the conversation is generally about and it has a history or messages.

import Foundation
import GenKit
import SharedKit

public struct Conversation: Codable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var picture: Asset?
    public var messages: [Message]
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case none
    }
    
    public init(id: String = .id, title: String = Self.titlePlaceholder, subtitle: String? = nil, picture: Asset? = nil,
                messages: [Message] = [], state: State = .none) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.picture = picture
        self.messages = messages
        self.state = state
        self.created = .now
        self.modified = .now
    }
    
    mutating func apply(conversation: Conversation) {
        self.title = conversation.title
        self.subtitle = conversation.subtitle
        self.picture = conversation.picture
        self.messages = conversation.messages
        self.state = conversation.state
        self.modified = .now
    }
    
    public static var empty: Self { .init() }
    public static var titlePlaceholder = "New Conversation"
}

extension Conversation: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Conversation {
    
    public static var preview: Conversation = {
        .init(messages: Agent.preview.instructions + [
            .init(role: .assistant, content: "What can I help you with today?"),
            .init(role: .user, content: "Explain thermodynamics like I'm five"),
            .init(role: .assistant, content: """
                Thermodynamics is like a set of rules that explain how heat, energy, and things that move around \
                work. It helps us understand why things can get hot or cold, and why some things can move while \
                others stay still.

                Think of all the things around you, like a toy car or a glass of water. Thermodynamics helps us \
                understand how these things behave when they interact with heat or energy. It's like a special \
                language that scientists use to talk about how things work together.
                """)
        ])
    }()
}
