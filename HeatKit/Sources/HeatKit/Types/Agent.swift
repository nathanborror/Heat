import Foundation

public struct Agent: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var tagline: String
    public var picture: Media
    public var system: String?
    public var created: Date
    public var modified: Date
    
    init(id: String = UUID().uuidString, name: String, tagline: String, picture: Media, system: String? = nil) {
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

extension Agent {
    public static var empty: Agent = .init(name: "", tagline: "", picture: .none)
}
