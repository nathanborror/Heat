import Foundation
import SharedKit

public struct Artifact: Identifiable, Codable {
    public var id: String
    public var url: URL?
    public var title: String?
    public var summary: String?
    public var source: String?
    public var created: Date
    public var modified: Date
    
    public init(id: String = .id, url: URL? = nil, title: String? = nil, summary: String? = nil, source: String? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.summary = summary
        self.source = source
        self.created = .now
        self.modified = .now
    }
    
    mutating func apply(artifact: Artifact) {
        self.url = artifact.url
        self.title = artifact.title
        self.summary = artifact.summary
        self.source = artifact.source
        self.modified = .now
    }
}

extension Artifact: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}
