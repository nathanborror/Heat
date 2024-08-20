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
    public var suggestions: [String]
    public var tools: Set<Tool>
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case suggesting
        case none
    }
    
    public init(id: String = .id, title: String = Self.titlePlaceholder, subtitle: String? = nil, picture: Asset? = nil,
                messages: [Message] = [], suggestions: [String] = [], tools: Set<Tool> = [], state: State = .none) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.picture = picture
        self.messages = messages
        self.suggestions = suggestions
        self.tools = tools
        self.state = state
        self.created = .now
        self.modified = .now
    }
    
    mutating func apply(conversation: Conversation) {
        self.title = conversation.title
        self.subtitle = conversation.subtitle
        self.picture = conversation.picture
        self.messages = conversation.messages
        self.suggestions = conversation.suggestions
        self.tools = conversation.tools
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
