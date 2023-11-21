import Foundation

public struct Preferences: Codable, Hashable {
    public var host: String
    public var preferredModelID: String
    public var isDebug: Bool
    public var isSuggesting: Bool
    public var modified: Date
    
    init(host: String = "127.0.0.1:8080") {
        self.host = host
        self.preferredModelID = ""
        self.isDebug = true
        self.isSuggesting = false
        self.modified = .now
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(modified)
    }
    
    public static var empty = Preferences()
}
