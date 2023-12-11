import Foundation

public struct Message: Codable, Identifiable, Hashable {
    public var id: String
    public var kind: Kind
    public var role: Role
    public var content: String
    public var done: Bool
    public var created: Date
    public var modified: Date
    
    public enum Role: Codable {
        case system, assistant, user
    }
    
    public enum Kind: Codable {
        case none, instruction
    }
    
    init(id: String = UUID().uuidString, kind: Kind = .none, role: Role, content: String, done: Bool = true) {
        self.id = id
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
