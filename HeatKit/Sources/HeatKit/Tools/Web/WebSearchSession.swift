import Foundation
import QuartzCore
import Fuzi

public actor WebSearchSession {
    public static var shared = WebSearchSession()

    private init() {}

    public func search(query: String) async throws -> WebSearchResponse {
        let engine = DuckSearch()
        return try await engine.search(web: query)
    }

    public func searchImages(query: String) async throws -> WebSearchResponse {
        let engine = GoogleSearch()
        return try await engine.search(images: query)
    }
}
