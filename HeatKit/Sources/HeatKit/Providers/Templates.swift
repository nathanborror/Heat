import Foundation
import GenKit
import SharedKit
import OSLog

private let logger = Logger(subsystem: "Templates", category: "Kit")

public struct Template: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var name: String
    public var instructions: String
    public var context: [String: String]
    public var toolIDs: Set<String>
    public var created: Date
    public var modified: Date
    
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case assistant
        case prompt
    }
    
    public init(id: String = .id, kind: Kind, name: String, instructions: String, context: [String: String] = [:], toolIDs: Set<String> = []) {
        self.id = id
        self.kind = kind
        self.name = name
        self.instructions = instructions
        self.context = context
        self.toolIDs = toolIDs
        self.created = .now
        self.modified = .now
    }
    
    public static var empty: Self {
        .init(kind: .prompt, name: "", instructions: "")
    }
    
    mutating func apply(template: Template) {
        kind = template.kind
        name = template.name
        instructions = template.instructions
        context = template.context
        toolIDs = template.toolIDs
        modified = .now
    }
}

actor TemplateStore {
    private var templates: [Template] = []
    
    func save(_ templates: [Template]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(templates)
        try data.write(to: self.dataURL, options: [.atomic])
        self.templates = templates
    }
    
    func load() throws -> [Template] {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        templates = try decoder.decode([Template].self, from: data)
        return templates
    }
    
    private var dataURL: URL {
        get throws {
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("TemplateData.plist")
        }
    }
}

@MainActor
@Observable
public final class TemplatesProvider {
    public static let shared = TemplatesProvider()
    
    public private(set) var templates: [Template] = []
    
    public func get(_ id: String) throws -> Template {
        guard let template = templates.first(where: { $0.id == id }) else {
            throw TemplatesProviderError.notFound
        }
        return template
    }
    
    public func upsert(_ template: Template) async throws {
        var templates = self.templates
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            var existing = templates[index]
            existing.apply(template: template)
            templates[index] = existing
        } else {
            templates.insert(template, at: 0)
        }
        self.templates = templates
        try await save()
    }
    
    public func delete(_ id: String) async throws {
        templates.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func reset() async throws {
        logger.debug("Resetting templates...")
        templates = Defaults.templates
        try await save()
    }
    
    // MARK: - Private
    
    private let store = TemplateStore()
    
    private init() {
        Task { try await load() }
    }
    
    private func load() async throws {
        templates = try await store.load()
    }
    
    private func save() async throws {
        try await store.save(templates)
    }
}

public enum TemplatesProviderError: Error {
    case notFound
}
