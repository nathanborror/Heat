import Foundation
import OSLog
import SharedKit
import UniformTypeIdentifiers
import CryptoKit

private let logger = Logger(subsystem: "Files", category: "Providers")

public struct File: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var path: String
    public var mimetype: UTType
    public var metadata: [String: Value]
    public var created: Date
    public var modified: Date

    public init(id: String = .id, path: String, name: String? = nil, mimetype: UTType) {
        self.id = id
        self.path = path
        self.mimetype = mimetype
        self.metadata = [:]
        self.created = .now
        self.modified = .now

        // metadata
        self.name = name
    }

    func apply(_ file: File) -> File {
        var existing = self
        existing.path = file.path
        existing.mimetype = file.mimetype
        existing.metadata = file.metadata
        existing.modified = file.modified
        return existing
    }

    public var name: String? {
        set { metadata["name"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["name"]?.stringValue }
    }

    public var isExpanded: Bool {
        set { metadata["expanded"] = .bool(newValue) }
        get { metadata["expanded"]?.boolValue ?? false }
    }

    public var order: Int {
        set { metadata["order"] = .int(newValue) }
        get { metadata["order"]?.intValue ?? 0 }
    }

    public var flag: String? {
        set { metadata["flag"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["flag"]?.stringValue }
    }
}

extension File {

    public var isImage: Bool {
        mimetype == .image
    }

    public var isVideo: Bool {
        mimetype == .video
    }

    public var isAudio: Bool {
        mimetype == .audio
    }

    public var isText: Bool {
        mimetype == .text
    }

    public var isDirectory: Bool {
        mimetype == .directory
    }

    public var isDocument: Bool {
        isJSON && path.hasSuffix("document")
    }

    public var isConversation: Bool {
        isJSON && path.hasSuffix("conversation")
    }

    public var isInstruction: Bool {
        isJSON && path.hasSuffix("instruction")
    }
    
    public var isJSON: Bool {
        mimetype == .json
    }
}

public struct FileTree: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var children: [FileTree]?

    init(id: String, children: [FileTree]? = nil) {
        self.id = id
        self.children = children
    }
}

@MainActor @Observable
public final class FilesProvider {
    public static let shared = FilesProvider()

    public private(set) var config: Config = .init()
    public private(set) var files: [File] = []

    public private(set) var ignores: [String] = [".DS_Store", ".config"]

    public enum Error: Swift.Error, CustomStringConvertible {
        case cachedMetadataNotFound
        case cachedDataNotFound
        case badServerResponse
        case userNotFound
        case unknown(String)

        public var description: String {
            switch self {
            case .cachedMetadataNotFound:
                "Cached metadata not found"
            case .cachedDataNotFound:
                "Cahced data not found"
            case .badServerResponse:
                "Bad server response"
            case .userNotFound:
                "User not found"
            case .unknown(let details):
                "Unknown error: \(details)"
            }
        }
    }

    private let persistenceURL = URL.documentsDirectory
    private var persistenceRestoration: Task<Void, Swift.Error>?

    public init() {
        self.persistenceRestoration = Task { try await restore() }
    }

    public func ready() async throws {
        try await persistenceRestoration?.value
    }

    /// Restores all cached file metadata within all top-level directories (e.g. USER_BUCKET/.info/metadata)
    public func restore() async throws {

        // Restore config
        do {
            let configURL = persistenceURL.appending(path: ".config")
            let data = try Data(contentsOf: configURL)
            self.config = try decoder.decode(Config.self, from: data)
        } catch {
            logger.error("[FilesProvider] Failed to restore config (likely doesn't exist)")
        }

        // Restore file metadata
        let fileIDs = try FileManager.default.list(contentsOf: persistenceURL.appending(path: ".app/metadata/"), ignore: ignores)
        self.files = try fileIDs.map {
            let data = try Data(contentsOf: $0)
            return try decoder.decode(File.self, from: data)
        }
    }

    public func reset() {
        self.files = []
        self.config = .init()
    }

    public func cache(data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic, createDirectories: true)
    }

    public func cache(object: any Encodable, to url: URL) throws {
        let data = try encoder.encode(object)
        try cache(data: data, to: url)
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let encoder = JSONDecoder()
        return encoder
    }()
}

// Config

extension FilesProvider {

    public func cacheConfig(_ config: Config) throws {
        let mutated = self.config.apply(config)
        self.config = mutated
        try cache(object: config, to: .documentsDirectory.appending(path: ".config"))
    }
}

// Metadata

extension FilesProvider {

    // Cache Reads

    public func cachedFileList(mimetype: UTType? = nil, parentID: String? = nil) -> [File] {
        var files = self.files
        if let mimetype {
            files = files.filter { $0.mimetype == mimetype }
        }
        if let parentID, let parent = try? cachedFileMetadata(parentID) {
            files = files.filter { $0.path.hasPrefix(parent.path) }
        }
        return files
    }

    public func cachedFileDirectoryTree(parentID: String? = nil) throws -> [FileTree] {
        if let parentID {
            let file = try cachedFileMetadata(parentID)
            let ref = try calculateFileHierarchy(parentID: file.id, path: file.path)
            return ref.children ?? []
        } else {
            let ref = try calculateFileHierarchy()
            return ref.children ?? []
        }
    }

    public func cachedFileMetadata(_ fileID: String) throws -> File {
        guard let out = files.first(where: { $0.id == fileID }) else {
            throw Error.cachedMetadataNotFound
        }
        return out
    }

    public func cachedFileObject<T: Decodable>(_ type: T.Type, fileID: String) throws -> T {
        let data = try cachedFileData(fileID)
        return try decoder.decode(type, from: data)
    }

    public func cachedFileData(_ fileID: String) throws -> Data {
        let file = try cachedFileMetadata(fileID)
        let url = persistenceURL
            .appending(path: file.path)
        do {
            return try Data(contentsOf: url)
        } catch {
            throw Error.cachedDataNotFound
        }
    }

    // Cache Writes

    public func cacheFileMetadata(_ file: File) async throws {
        try await ready()
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            let mutated = files[index].apply(file)
            files[index] = mutated
        } else {
            files.append(file)
        }
        let url = persistenceURL
            .appending(path: ".app/metadata")
            .appending(path: file.id)
        try cache(object: file, to: url)
    }

    public func cacheFileObject(_ object: any Encodable, fileID: String) async throws {
        try await ready()
        let data = try encoder.encode(object)
        try await cacheFileData(data, fileID: fileID)
    }

    public func cacheFileData(_ data: Data, fileID: String) async throws {
        try await ready()
        let file = try cachedFileMetadata(fileID)
        let url = persistenceURL
            .appending(path: file.path)
        try cache(data: data, to: url)
    }

    // Cache Deletes

    /// Deletes both the file metadata and the file data from the cache.
    public func cacheFileDelete(_ fileID: String) async throws {
        try await ready()

        let file = try cachedFileMetadata(fileID)
        let metadataURL = persistenceURL
            .appending(path: ".app/metadata")
            .appending(path: file.id)
        let dataURL = persistenceURL
            .appending(path: file.path)

        do {
            try FileManager.default.removeItem(at: metadataURL)
            try FileManager.default.removeItem(at: dataURL)
        } catch {
            logger.error("[FilesProvider] Cache delete error: \(error)")
        }
        files.removeAll(where: { $0.id == fileID })
    }

    // Ordering

    public func moveFiles(_ indexSet: IndexSet, to offset: Int, context: [File]) async throws {
        try await ready()

        // Get the user's files
        let files = cachedFileList()

        // File IDs that are in the given context (folder)
        let fileIDs = context.map { $0.id }

        // Re-order files in the given context
        var existingFiles = files.filter { fileIDs.contains($0.id) }.sorted { $0.order < $1.order }
        existingFiles.move(fromOffsets: indexSet, toOffset: offset)

        // Save new ordering
        var index = 0
        for existing in existingFiles {
            var file = existing
            file.order = index

            // Cache file metadata and send to remote server
            try await cacheFileMetadata(file)
            index += 1
        }
    }
}

// MARK: - Private

extension FilesProvider {

    private func calculateFileHierarchy(parentID: String? = nil, path: String = "") throws -> FileTree {
        let componentCount = URL(string: path)?.pathComponents.count ?? 0
        let files = cachedFileList(parentID: parentID)
        let children = files.filter {
            $0.path.hasPrefix(path) &&
            URL(string: $0.path)!.pathComponents.count == componentCount + 1
        }
        let refs = try children.map { try calculateFileHierarchy(parentID: $0.id, path: $0.path) }
        return .init(id: parentID ?? "", children: refs.isEmpty ? nil : refs)
    }
}
