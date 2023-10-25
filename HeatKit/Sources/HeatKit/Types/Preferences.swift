import Foundation

public struct Preferences: Codable, Hashable {
    public var host: String
    public var modified: Date
    
    init(host: String = "127.0.0.1:8080") {
        self.host = host
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(modified)
    }
    
    public static var empty = Preferences()
}
