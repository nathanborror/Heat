import Foundation
import OSLog
import NaturalLanguage
import SQLiteVec
import SharedKit

private let logger = Logger(subsystem: "Memory", category: "Kit")

public struct Memory: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var content: String

    public var similarID: Int?
    public var similarContent: String?
    public var similarDistance: Float?

    public enum Kind: String, Codable, Sendable {
        case file
        case none
    }

    public init(id: String = .id, kind: Kind = .none, content: String, similarID: Int? = nil,
                similarContent: String? = nil, similarDistance: Float? = nil) {
        self.id = id
        self.kind = kind
        self.content = content
        self.similarID = similarID
        self.similarContent = similarContent
        self.similarDistance = similarDistance
    }
}

actor MemoryStore {
    private let db: Database
    private let embeddingProvider: EmbeddingProvider

    init() {
        do {
            // Initialize SQLiteVec before instantiating the Database, if this is done after
            // it will result in an error due to not being able to load the sqlite-vec extension.
            try SQLiteVec.initialize()
            logger.debug("[MemoryStore] Initialized SQLiteVec")

            self.db = try Database(.uri(Self.dataURL.absoluteString))
            self.embeddingProvider = NLEmbedding.sentenceEmbedding(for: .english)!
        } catch {
            fatalError("failed to establish sqlite database")
        }
    }

    public func setup() async throws {
        do {
            try await db.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id TEXT PRIMARY KEY,
                    content_type TEXT NOT NULL,
                    content TEXT NOT NULL,
                    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                """)
            try await db.execute("""
                CREATE TABLE IF NOT EXISTS chunks (
                    id INTEGER PRIMARY KEY,
                    document_id TEXT NOT NULL,
                    document_index INTEGER NOT NULL,
                    content TEXT NOT NULL
                );
                """)
            try await db.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS embeddings USING vec0(
                    chunk_id INTEGER PRIMARY KEY,
                    embedding float[512]
                );
                """)
            logger.debug("[MemoryStore] Database ready")
        } catch {
            logger.error("[MemoryStore] Failed to setup database: \(error)")
        }
    }

    public func selectAll() async throws -> [Memory] {
        let rows = try await db.query("SELECT id, content_type, content FROM documents")
        return rows.compactMap { row in
            guard
                let id = row["id"] as? String,
                let kindStr = row["content_type"] as? String,
                let kind = Memory.Kind(rawValue: kindStr),
                let content = row["content"] as? String
            else {
                return nil
            }
            return .init(
                id: .init(id),
                kind: kind,
                content: content
            )
        }
    }

    public func select(kind: Memory.Kind) async throws -> [Memory] {
        let rows = try await db.query("SELECT id, content_type, content FROM documents WHERE content_type = ?", params: [kind.rawValue])
        return rows.compactMap { row in
            guard
                let id = row["id"] as? String,
                let kindStr = row["content_type"] as? String,
                let kind = Memory.Kind(rawValue: kindStr),
                let content = row["content"] as? String
            else {
                return nil
            }
            return .init(
                id: .init(id),
                kind: kind,
                content: content
            )
        }
    }

    public func select(id: String) async throws -> Memory {
        guard let row = try await db.query("SELECT id, content_type, content FROM documents WHERE id = ?", params: [id]).first else {
            throw MemoryProvider.Error.notFound
        }
        guard
            let id = row["id"] as? String,
            let kindStr = row["content_type"] as? String,
            let kind = Memory.Kind(rawValue: kindStr),
            let content = row["content"] as? String
        else {
            throw MemoryProvider.Error.notFound
        }
        return .init(
            id: .init(id),
            kind: kind,
            content: content
        )
    }

    public func select(similar query: String, k: Int = 5) async throws -> [Memory] {
        guard let vector = embeddingProvider.vector(for: query) else {
            throw MemoryProvider.Error.cannotCreateVector
        }
        let vectorEmbeddings = vector.map { Float($0) }
        let rows = try await db.query(
            """
            SELECT
                chunks.id AS chunk_id,,
                chunks.content AS chunk_content,
                documents.id,
                documents.content_type,
                documents.content,
                distance
            FROM
                embeddings
            LEFT JOIN chunks ON
                chunks.id = embeddings.chunk_id
            LEFT JOIN documents ON
                documents.id = chunks.document_id
            WHERE
                embedding MATCH ? AND k = ?
            ORDER BY
                distance
            """,
            params: [vectorEmbeddings, k]
        )
        return rows.compactMap { row -> Memory? in
            guard
                let similarID = row["chunk_id"] as? Int,
                let similarContent = row["chunk_content"] as? String,
                let similarDistance = row["distance"] as? Float,
                let memoryID = row["id"] as? String,
                let memoryKindStr = row["content_type"] as? String,
                let memoryKind = Memory.Kind(rawValue: memoryKindStr),
                let memoryContent = row["content"] as? String
            else {
                return nil
            }
            return .init(
                id: .init(memoryID),
                kind: memoryKind,
                content: memoryContent,
                similarID: similarID,
                similarContent: similarContent,
                similarDistance: similarDistance
            )
        }
    }

    public func insert(_ memory: Memory) async throws {
        try await db.execute(
            "INSERT INTO documents (id, content_type, content) VALUES (?, ?, ?);",
            params: [memory.id, memory.kind.rawValue, memory.content]
        )
        logger.debug("[MemoryStore] Inserted document")

        let chunks = split(memory.content)
        for (index, chunk) in chunks.enumerated() {
            try await db.execute(
                "INSERT INTO chunks (document_id, content, document_index) VALUES (?, ?, ?);",
                params: [memory.id, chunk, index]
            )
            let chunkID = await db.lastInsertRowId

            guard let vector = embeddingProvider.vector(for: chunk) else {
                throw MemoryProvider.Error.cannotCreateVector
            }
            let vectorEmbeddings = vector.map { Float($0) }
            try await db.execute(
                "INSERT INTO embeddings (chunk_id, embedding) VALUES (?, ?);",
                params: [chunkID, vectorEmbeddings]
            )
        }
        logger.debug("[MemoryStore] Inserted chunks (\(chunks.count)) and embeddings")
    }

    public func delete(_ memory: Memory) async throws {
        try await db.execute(
            """
            BEGIN TRANSACTION;
            DELETE FROM embeddings WHERE chunk_id IN (SELECT id FROM WHERE document_id = ?);
            DELETE FROM chunks WHERE document_id = ?;
            DELETE FROM documents WHERE id = ?;
            COMMIT;
            """, params: [memory.id])
        logger.debug("[MemoryStore] Deleted memory")
    }

    public func deleteAll() async throws {
        try await db.execute(
            """
            BEGIN TRANSACTION;
            DELETE FROM documents;
            DELETE FROM chunks;
            DELETE FROM embeddings;
            COMMIT;
            """)
        logger.debug("[MemoryStore] Deleted all memories")
    }

    // Private

    private func split(_ text: String, maxTokens: Int = 512) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var chunks: [String] = []
        var currentChunk: [String] = []
        var currentTokenCount = 0

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            if currentTokenCount + token.count > maxTokens {
                chunks.append(currentChunk.joined(separator: " "))
                currentChunk = [token]
                currentTokenCount = token.count
            } else {
                currentChunk.append(token)
                currentTokenCount += token.count
            }
            return true
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: " "))
        }

        return chunks
    }

    private static let dataURL = {
        let dir = URL.documentsDirectory.appending(path: ".app", directoryHint: .isDirectory)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("memory.sqlite", conformingTo: .database)
    }()
}

/// MemoryProvider provides a basic interface for storing and retrieving textual infromation. When text is stored it is split into chunks and embedded in a vector
/// database to allow similarity search.
@MainActor @Observable
public final class MemoryProvider {
    public static let shared = MemoryProvider()

    public func get() async throws -> [Memory] {
        try await store.selectAll()
    }

    public func get(_ id: String) async throws -> Memory {
        try await store.select(id: id)
    }

    public func get(kind: Memory.Kind) async throws -> [Memory] {
        try await store.select(kind: kind)
    }

    public func get(similar: String) async throws -> [Memory] {
        try await store.select(similar: similar)
    }

    public func upsert(_ memory: Memory) async throws {
        try await store.insert(memory)
    }

    public func delete(_ id: String) async throws {
        let memory = try await get(id)
        try await store.delete(memory)
    }

    public func reset() async throws {
        try await store.deleteAll()
    }

    // Private

    private let store = MemoryStore()

    private init() {
        Task { try await store.setup() }
    }
}

extension MemoryProvider {

    public enum Error: Swift.Error {
        case notFound
        case cannotCreateVector
    }
}

protocol EmbeddingProvider {
    func vector(for string: String) -> [Double]?
}

extension NLEmbedding: EmbeddingProvider {}
