import Foundation
import Fuzi

public protocol WebSearch {
    func search(web query: String) async throws -> WebSearchResponse
}

public protocol WebImageSearch {
    func search(images query: String) async throws -> WebSearchResponse
}

// MARK: Types

enum WebSearchError: Error {
    case invalidHTML
    case missingElement(String)
}

enum WebSearchUserAgent: String {
    case desktop = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    case mobile = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1"
}

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

extension Fuzi.XMLElement {

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
