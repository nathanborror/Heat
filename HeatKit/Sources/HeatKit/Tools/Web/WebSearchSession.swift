import Foundation
import QuartzCore
import Fuzi

public actor WebSearchSession {
    public static var shared = WebSearchSession()
    
    private init() {}
    
    public func search(query: String) async throws -> WebSearchResponse {
        let engine = GoogleSearch()
        return try await engine.search(query: query)
    }
    
    public func searchNews(query: String) async throws -> WebSearchResponse {
        let engine = GoogleSearch()
        return try await engine.searchNews(query: query)
    }
    
    public func searchImages(query: String) async throws -> WebSearchResponse {
        let engine = GoogleSearch()
        return try await engine.searchImages(query: query)
    }
}

// Below from: https://github.com/nate-parrott/chattoys

public struct GoogleSearch {

    private let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    private let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1"
    
    public init() {}

    public func search(query: String) async throws -> WebSearchResponse {
        var urlComponents = URLComponents(string: "https://www.google.com/search")!
        urlComponents.queryItems = [
            .init(name: "q", value: query),
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(desktopUserAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!

        let start = CACurrentMediaTime()
        let resp = try extractResults(html: html, baseURL: baseURL, query: query)
        print("[Timing] [GoogleSearch] Parsed at \(CACurrentMediaTime() - start)")
        return resp
    }
    
    public func searchNews(query: String) async throws -> WebSearchResponse {
        var urlComponents = URLComponents(string: "https://www.google.com/search")!
        urlComponents.queryItems = [
            .init(name: "q", value: query),
            .init(name: "tbm", value: "nws"),
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(desktopUserAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!

        let start = CACurrentMediaTime()
        let resp = try extractNewsResults(html: html, baseURL: baseURL, query: query)
        print("[Timing] [GoogleNewsSearch] Parsed at \(CACurrentMediaTime() - start)")
        return resp
    }

    public func searchImages(query: String) async throws -> WebSearchResponse {
        var urlComponents = URLComponents(string: "https://www.google.com/search")!
        urlComponents.queryItems = [
            .init(name: "q", value: query),
            .init(name: "tbm", value: "isch"), // to be matched = image search
            .init(name: "gbv", value: "1"), // google basic version = 1 (no js)
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(mobileUserAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!
        
        let start = CACurrentMediaTime()
        let resp = try extractImageResults(html: html, baseURL: baseURL, query: query)
        print("[Timing] [GoogleImageSearch] Parsed at \(CACurrentMediaTime() - start)")
        return resp
    }
    
    // MARK: Private
    
    private func extractResults(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        let doc = try Fuzi.HTMLDocument(string: html)

        guard let main = doc.css("#main").first else {
            throw SearchError.missingMainElement
        }

        var results = [WebSearchResult]()
        // Exclude role=heading; this indicates an image section
        // Exclude aria-hidden=true; this indicates the 'more results' cell
        // a:has(h3:not([role=heading], [aria-hidden=true]))
        let anchors = main.css("a").filter { el in
            let h3s = el.css("h3")
                .filter { $0.attr("role") != "header" && $0.attr("aria-hidden") != "true" }
            return h3s.count > 0
        }
        for anchor in anchors {
            if let result = try anchor.extractSearchResultFromAnchor(baseURL: baseURL) {
                results.append(result)
            }
        }

        // Try fetching youtube results and insert at position 1
        if let youtubeResults = try main.extractYouTubeResults() {
            results.insert(contentsOf: youtubeResults, at: min(1, results.count))
        }
        return .init(query: query, results: results)
    }
    
    private func extractNewsResults(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        let doc = try Fuzi.HTMLDocument(string: html)

        guard let main = doc.css("#main").first else {
            throw SearchError.missingMainElement
        }

        let results = main.css("a").map { el in
            let urls = el.xpath("//a[.//div[@role='heading']]/@href")
            let headers = el.xpath("//div[@role='heading'][@aria-level='3']/text()")
            let descriptions = el.xpath("//div[@role='heading'][@aria-level='3']/following-sibling::div[1]/text()")
         
            return zip(urls, zip(headers, descriptions)).map {
                WebSearchResult(url: URL(string: $0.stringValue)!, title: $1.0.stringValue, description: $1.1.stringValue)
            }
        }.flatMap { $0 }
        return .init(query: query, results: results)
    }

    private func extractImageResults(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        let doc = try Fuzi.HTMLDocument(string: html)
        let results = doc.css("a[href]")
            .filter { $0.attr("href")?.starts(with: "/imgres") ?? false }
            .compactMap { el -> WebSearchResult? in
                guard let href = el.attr("href"),
                      let comps = URLComponents(string: href),
                      let imgUrlStr = comps.queryItems?.first(where: { $0.name == "imgurl" })?.value,
                      let imgUrl = URL(string: imgUrlStr),
                      let siteUrlStr = comps.queryItems?.first(where: { $0.name == "imgrefurl" })?.value,
                      let siteUrl = URL(string: siteUrlStr)
                else {
                    return nil
                }
                return .init(url: siteUrl, image: imgUrl)
        }
        return WebSearchResponse(query: query, results: results)
    }
    
    enum SearchError: Error {
        case invalidHTML
        case missingMainElement
    }
}

private extension Fuzi.XMLElement {
    
    func extractYouTubeResults() throws -> [WebSearchResult]? {
        var results = [WebSearchResult]()
        // Search for elements with a href starting with https://www.youtube.com, which contain a div role=heading
        // a[href^='https://www.youtube.com']:has(div[role=heading])
        for element in css("a[href]") {
            guard let link = element.attr("href"), link.hasPrefix("https://www.youtube.com") else { continue }
            guard let parsed = URL(string: link) else { continue }
            guard let title = element.css("div[role='heading'] span").first?.stringValue else { continue }
            results.append(WebSearchResult(url: parsed, title: title, description: nil))
        }
        return results
    }

    func extractSearchResultFromAnchor(baseURL: URL) throws -> WebSearchResult? {
        // First, extract the URL
        guard let href = attr("href"),
              let parsed = URL(string: href, relativeTo: baseURL)
        else {
            return nil
        }
        // Then, extract title:
        guard let title = css("h3").first?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }

        let description: String? = { () -> String? in
            guard let farParent = self.nthParent(5) else { return nil }
            // First, look for an element with `div[style='-webkit-line-clamp:2']`
            if let div = farParent.css("div[style='-webkit-line-clamp:2']").first,
               let text = div.stringValue.nilIfEmptyOrJustWhitespace {
                return text
            }

            // If not, iterate backwards through child divs (except the first one) and look for one with a non-empty `<span>`
            let divChildren = Array(farParent.children.filter { $0.tag == "div" }.dropFirst())
            for div in divChildren.reversed() {
                if let span = div.css("span").first, let text = span.stringValue.nilIfEmptyOrJustWhitespace {
                    return text
                }
            }
            return nil
        }()
        
        return WebSearchResult(url: parsed, title: title, description: description)
    }

    var firstDescendantWithInnerText: Fuzi.XMLElement? {
        for child in children {
            if child.hasChildTextNodes {
                return child
            }
            if let desc = child.firstDescendantWithInnerText {
                return desc
            }
        }
        return nil
    }

    var hasChildTextNodes: Bool {
        let nonBlankNodes = childNodes(ofTypes: [.Text]).filter { $0.stringValue.nilIfEmptyOrJustWhitespace != nil }
        return !nonBlankNodes.isEmpty
    }

    func nthParent(_ n: Int) -> Fuzi.XMLElement? {
        if n <= 0 {
            return self
        }
        return parent?.nthParent(n - 1)
    }
}

// MARK: Types

public struct WebSearchResponse: Codable, Sendable {
    public var query: String
    public var results: [WebSearchResult]

    public init(query: String, results: [WebSearchResult]) {
        self.query = query
        self.results = results
    }
}

public struct WebSearchResult: Codable, Sendable {
    public var url: URL
    public var title: String?
    public var description: String?
    public var image: URL?

    public init(url: URL, title: String? = nil, description: String? = nil, image: URL? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.image = image
    }
}
