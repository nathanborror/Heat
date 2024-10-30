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

        let (data, response) = try await URLSession.shared.data(for: request)
        let baseURL = response.url ?? urlComponents.url!
        let resp = try extractResults(data, baseURL: baseURL, query: query)
        return resp
    }
}

extension DuckSearch {

    private func extractResults(_ data: Data, baseURL: URL, query: String) throws -> WebSearchResponse {

        // Do not use the code path `Fuzi.HTMLDocument(string:)` because it will lead to silent parsing failures
        // only on release builds. There be demons in this package.
        let doc = try parse(data: data)
        let results = doc.css("#links .result").map {
            WebSearchResult(
                url: .init(string: $0.firstChild(css: "h2 a")?.attr("href") ?? "")!,
                title: $0.firstChild(css: "h2 a")?.stringValue ?? "",
                description: $0.firstChild(css: ".result__snippet")?.stringValue ?? ""
            )
        }
        return WebSearchResponse(query: query, results: results)
    }

    private func parse(data: Data) throws -> Fuzi.HTMLDocument {
        // Do not use the code path `Fuzi.HTMLDocument(string:)` because it will lead to silent parsing failures
        // only on release builds. There be demons in this package.
        try Fuzi.HTMLDocument(data: data)
    }
}
