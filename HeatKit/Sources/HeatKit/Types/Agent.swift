import Foundation

public struct Agent: Codable, Identifiable {
    public var id: String
    public var name: String
    public var tagline: String
    public var picture: Media
    public var messages: [Message]
    public var created: Date
    public var modified: Date
    
    init(id: String = UUID().uuidString, name: String, tagline: String, picture: Media, messages: [Message]) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.picture = picture
        self.messages = messages
        self.created = .now
        self.modified = .now
    }
}

extension Agent: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Agent {

    public static var empty: Self {
        .init(name: "", tagline: "", picture: .none, messages: [])
    }
    
    public static var preview: Self = .vent
}
