import Foundation

public struct Preferences: Codable, Hashable {
    public var host: URL?
    public var preferredModelID: String
    public var isDebug: Bool
    public var isSuggesting: Bool
    public var modified: Date
    
    init() {
        self.host = nil
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
