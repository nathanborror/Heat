import Foundation

public struct Agent: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var picture: Media
    public var system: String?
    public var prompt: String
    public var created: Date
    public var modified: Date
    
    init(id: String = UUID().uuidString, name: String, picture: Media, system: String? = nil, prompt: String) {
        self.id = id
        self.name = name
        self.picture = picture
        self.system = system
        self.prompt = prompt
        self.created = .now
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Agent {
    public static var empty: Agent = .init(name: "", picture: .none, prompt: "")
}
