import Foundation

public struct Agent: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var tagline: String
    public var picture: Media
    public var system: String
    public var created: Date
    public var modified: Date
    
    init(id: String = UUID().uuidString, name: String, tagline: String, picture: Media, system: String) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.picture = picture
        self.system = system
        self.created = .now
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

public struct AgentChat: Codable, Identifiable, Hashable {
    public var id: String
    public var agentID: String
    public var system: String
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
    
    init(id: String = UUID().uuidString, agentID: String, system: String) {
        self.id = id
        self.agentID = agentID
        self.system = system
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

public struct Message: Codable, Identifiable, Hashable {
    public var id: String
    public var model: String
    public var kind: Kind
    public var role: Role
    public var content: String
    public var done: Bool
    public var created: Date
    public var modified: Date
    
    public enum Role: Codable {
        case assistant, user
    }
    
    public enum Kind: Codable {
        case none, instruction
    }
    
    init(id: String = UUID().uuidString, model: String, kind: Kind = .none, role: Role, content: String, done: Bool) {
        self.id = id
        self.model = model
        self.kind = kind
        self.role = role
        self.content = content
        self.done = done
        self.created = .now
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

public enum Media: Codable, Equatable, Hashable {
    case filesystem(String)
    case bundle(String)
    case video(String)
    case color(String)
    case data(Data)
    case systemIcon(String, String)
    case none
}

public struct Preferences: Codable, Hashable {
    public var host: String
    public var model: String
    public var modified: Date
    
    init(host: String = "127.0.0.1:8080", model: String = "llama2:13b-chat") {
        self.host = host
        self.model = model
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(modified)
    }
    
    public static var empty = Preferences()
}
