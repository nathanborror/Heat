import Foundation
import Fuzi

public struct DuckSearch: WebSearch {

    let host = "https://html.duckduckgo.com/html"

    public func search(web query: String) async throws -> WebSearchResponse {
        let userAgent = WebSearchUserAgent.mobile

        var urlComponents = URLComponents(string: host)!
        urlComponents.queryItems = [.init(name: "q", value: query)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue(userAgent.rawValue, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .returnCacheDataElseLoad

        let (data, response) = try await session.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw WebSearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!
        let resp = try extractResults(html: html, baseURL: baseURL, query: query)
        return resp
    }

    private let session = {
        let memoryCapacity = 500 * 1024 * 1024 // 500 MB
        let diskCapacity = 500 * 1024 * 1024   // 500 MB
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let diskPath = cachesURL.appendingPathComponent("DuckSearchCache").path

        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: diskPath)
        URLCache.shared = cache

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy

        return URLSession(configuration: configuration)
    }()
}

extension DuckSearch {

    private func extractResults(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        var out = WebSearchResponse(
            query: query,
            results: []
        )
        let doc = try Fuzi.HTMLDocument(string: html)
        out.results = doc.css("#links .result").map {
            return WebSearchResult(
                url: .init(string: $0.firstChild(css: "h2 a")?.attr("href") ?? "")!,
                title: $0.firstChild(css: "h2 a")?.stringValue ?? "",
                description: $0.firstChild(css: ".result__snippet")?.stringValue ?? ""
            )
        }
        return out
    }
}
