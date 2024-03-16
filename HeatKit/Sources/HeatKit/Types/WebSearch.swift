import Foundation

public struct WebSearchResponse: Codable {
    public var query: String
    public var results: [WebSearchResult]
    public var infoBox: String?

    public init(query: String, results: [WebSearchResult], infoBox: String? = nil) {
        self.query = query
        self.results = results
        self.infoBox = infoBox
    }
}

public struct WebSearchResult: Codable {
    public var url: URL
    public var title: String
    public var description: String?

    public init(url: URL, title: String, description: String?) {
        self.url = url
        self.title = title
        self.description = description
    }
}
