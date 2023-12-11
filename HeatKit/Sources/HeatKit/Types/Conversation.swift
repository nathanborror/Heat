import Foundation

public struct Conversation: Codable, Identifiable {
    public var id: String
    public var modelID: String
    public var messages: [Message]
    public var suggestions: [String]?
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case suggesting
        case none
    }
    
    init(id: String = UUID().uuidString, modelID: String, messages: [Message] = [], suggestions: [String]? = nil) {
        self.id = id
        self.modelID = modelID
        self.messages = messages
        self.suggestions = suggestions
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
}

extension Conversation {
    
    public static var preview: Self {
        .init(
            modelID: Model.preview.id,
            messages: Agent.preview.messages,
            suggestions: [
                "I'm so frustrated",
                "My friend always cancels on me",
                "I'm feeling down today",
            ]
        )
    }
}
