import Foundation
import NaturalLanguage
import SQLiteVec

@MainActor @Observable
public final class DataStore {
    public static let shared = DataStore()
    
    let db: Database
    let embeddingProvider: EmbeddingProvider
    
    public func initialize() async throws {
        try SQLiteVec.initialize()
        
        do {
            try await db.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id INTEGER PRIMARY KEY,
                    text TEXT NOT NULL UNIQUE
                );
                """)
            try await db.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS embeddings USING vec0(
                    id INTEGER PRIMARY KEY,
                    embedding float[512]
                );
                """)
        } catch {
            print(error)
        }
    }
    
    public func write(text: String) async throws {
        guard let vector = embeddingProvider.vector(for: text) else {
            throw Error.cannotCreateVector
        }
        try await db.execute("INSERT INTO documents(text) VALUES(?);", params: [text])
        let lastInsertRowId = await db.lastInsertRowId
        let vectorEmbeddings = vector.map { Float($0) }
        try await db.execute("INSERT INTO embeddings(id, embedding) VALUES (?, ?);", params: [lastInsertRowId, vectorEmbeddings])
    }
    
    public func similar(to text: String, k: Int = 5) async throws -> [[String: Any]] {
        guard let vector = embeddingProvider.vector(for: text) else {
            throw Error.cannotCreateVector
        }
        let vectorEmbeddings = vector.map { Float($0) }
        return try await db.query(
            """
            SELECT
                embeddings.id as id, distance, text
            FROM
                embeddings
            LEFT JOIN documents ON
                documents.id = embeddings.id
            WHERE
                embedding MATCH ? AND k = ?
            ORDER BY
                distance
            """,
            params: [vectorEmbeddings, k]
        )
    }
    
    // Private
    
    private init() {
        do {
            self.db = try Database(.inMemory)
            self.embeddingProvider = NLEmbedding.sentenceEmbedding(for: .english)!
        } catch {
            fatalError("failed to establish sqlite database")
        }
    }
}

extension DataStore {
    enum Error: Swift.Error {
        case cannotCreateVector
    }
}

// MARK: - Embeddings

protocol EmbeddingProvider {
    func vector(for string: String) -> [Double]?
}

extension NLEmbedding: EmbeddingProvider {}
