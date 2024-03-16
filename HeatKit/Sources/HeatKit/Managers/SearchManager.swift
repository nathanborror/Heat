import Foundation
import QuartzCore
import Fuzi

public class SearchManager {
    
    public static var shared = SearchManager()
    
    init() {}
    
    public func search(query: String) async throws -> WebSearchResponse {
        let engine = GoogleSearchEngine()
        return try await engine.search(query: query)
    }
}

// Below from: https://github.com/nate-parrott/chattoys

public protocol WebSearchEngine {
    func search(query: String) async throws -> WebSearchResponse
}

public struct GoogleSearchEngine: WebSearchEngine {

    public init() {}

    public func search(query: String) async throws -> WebSearchResponse {
        var urlComponents = URLComponents(string: "https://www.google.com/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw SearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!

        let t2 = CACurrentMediaTime()
        let extracted = try extract(html: html, baseURL: baseURL, query: query)
        print("[Timing] [GoogleSearch] Parsed at \(CACurrentMediaTime() - t2)")
        
        return extracted
    }

    private func extract(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        let doc = try Fuzi.HTMLDocument(string: html)

        guard let main = doc.css("#main").first else {
            throw SearchError.missingMainElement
        }

        /*
         In the Google search result DOM tree:
         - #main contains all search results (but also some navigational stuff)
         - Results are wrapped in many layers of divs
         - Result links look like this: <a href=''>
           - They contain (several layers deep):
             - A url breadcrumbs view built out of divs
             - An h3 containing the result title
         - Result snippets can be found by:
            - Starting at the <a>
            - Going up three levels and selecting the _second_ div child
            - Finding the first child of this div that contains text, and extracting all inner text
         - Some results (e.g. youtube) may include multiple spans and <br> elements in their snippets.
         */

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
        return .init(query: query, results: results, infoBox: nil)
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
