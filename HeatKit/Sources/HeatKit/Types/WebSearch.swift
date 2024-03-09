import Foundation

public struct WebSearchResponse: Equatable, Codable {
    public var query: String
    public var results: [WebSearchResult]
    public var infoBox: String?

    public init(query: String, results: [WebSearchResult], infoBox: String? = nil) {
        self.query = query
        self.results = results
        self.infoBox = infoBox
    }
}

public struct WebSearchResult: Equatable, Codable, Identifiable {
    public var id: URL { url }
    public var url: URL
    public var title: String
    public var snippet: String?

    public init(url: URL, title: String, snippet: String?) {
        self.url = url
        self.title = title
        self.snippet = snippet
    }
}

extension WebSearchResult: CustomStringConvertible {
    public var description: String {
        let lines: [String] = [
            " - [\(url.absoluteString)]",
            "   \(title)",
            "   \(snippet?.truncateTail(maxLen: 80) ?? "[No snippet]")"
        ]
        return lines.joined(separator: "\n")
    }
}
