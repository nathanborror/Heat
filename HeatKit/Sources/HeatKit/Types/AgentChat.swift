import Foundation

public struct AgentChat: Codable, Identifiable, Hashable {
    public var id: String
    public var modelID: String
    public var agentID: String
    public var prompt: String?
    public var messages: [Message]
    public var context: [Int]
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case none
    }
    
    init(id: String = UUID().uuidString, modelID: String, agentID: String, prompt: String) {
        self.id = id
        self.agentID = agentID
        self.modelID = modelID
        self.prompt = prompt
        self.messages = []
        self.context = []
        self.state = .none
        self.created = .now
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}
