import Foundation
import SharedKit
import SwiftData

@Model
public final class Memory {
    @Attribute(.unique) public var id: String
    public var content: String
    public var created: Date
    public var modified: Date
    
    public init(id: String = .id, content: String, created: Date = .now, modified: Date = .now) {
        self.id = id
        self.content = content
        self.created = created
        self.modified = modified
    }
}

extension Memory {
    
    static var preview: Self {
        .init(content: "Lives in Nevada City, California")
    }
}

public actor MemoryDataPreview {
    
    @MainActor
    public static var container: ModelContainer = {
        return try! inMemoryContainer()
    }()
    
    static var inMemoryContainer: () throws -> ModelContainer = {
        let schema = Schema([Memory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let sample: [any PersistentModel] = [
            Memory.preview
        ]
        Task { @MainActor in
            sample.forEach {
                container.mainContext.insert($0)
            }
        }
        return container
    }
}
