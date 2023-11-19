import Foundation

public struct AgentChat: Codable, Identifiable {
    public var id: String
    public var modelID: String
    public var agentID: String
    public var system: String?
    public var messages: [Message]
    public var suggestions: [String]?
    public var context: [Int]
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case none
    }
    
    init(id: String = UUID().uuidString, modelID: String, agentID: String, system: String? = nil, messages: [Message] = [], suggestions: [String]? = nil) {
        self.id = id
        self.agentID = agentID
        self.modelID = modelID
        self.system = system
        self.messages = messages
        self.suggestions = suggestions
        self.context = []
        self.state = .none
        self.created = .now
        self.modified = .now
    }
}

extension AgentChat: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension AgentChat {
    
    public static var preview: Self {
        .init(modelID: Model.preview.id, agentID: Agent.preview.id, system: Agent.preview.system, messages: [
            .init(role: .assistant, content: "Hello there", done: true),
        ], suggestions: [
            "I'm so frustrated",
            "My friend always cancels on me",
            "I'm feeling down today",
        ])
    }
}
