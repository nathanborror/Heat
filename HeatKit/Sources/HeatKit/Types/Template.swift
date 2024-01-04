import Foundation
import SharedKit
import GenKit

public struct Template: Codable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var picture: Media
    public var messages: [Message]
    public var created: Date
    public var modified: Date
    
    public init(id: String = .id, title: String, subtitle: String? = nil, picture: Media = .none,
                messages: [Message] = []) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.picture = picture
        self.messages = messages
        self.created = .now
        self.modified = .now
    }
}

extension Template: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Template {

    public static var empty: Self {
        .init(title: "")
    }
    
    public static var preview: Self = .vent
}
