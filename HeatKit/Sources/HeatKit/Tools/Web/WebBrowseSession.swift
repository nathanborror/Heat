import Foundation
import GenKit
import Fuzi

public class WebBrowserSession {
    public static let shared = WebBrowserSession()
    
    private init() {}
    
    public func generateMarkdown(for url: String) async throws -> String? {
        guard let url = URL(string: url) else { return nil }
        return try await fetch(url: url, urlMode: .omit, hideJSONLD: true, hideImages: true)
    }
    
    public func generateSummary(service: ChatService, model: String, url: String) async throws -> String? {
        guard let url = URL(string: url) else { return nil }
        
        let markdown = try await fetch(url: url, urlMode: .omit, hideJSONLD: true, hideImages: true)
        let message = Message(role: .user, content: """
            Summarize the following:
            
            \(markdown)
            """)
        
        var summary: String? = nil
        await MessageManager()
            .append(message: message)
            .generate(service: service, model: model) { message in
                summary = message.content
            }
        return summary
    }
    
    // MARK: - Private
    
    private func fetch(url: URL, urlMode: FastHTMLProcessor.URLMode, hideJSONLD: Bool, hideImages: Bool) async throws -> String {
        var request = URLRequest(url: url)
        
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let resp = try await URLSession.shared.data(for: request)
        
        let proc = try FastHTMLProcessor(url: resp.1.url ?? url, data: resp.0)
        let markdown = proc.markdown(urlMode: urlMode, hideJSONLD: hideJSONLD, hideImages: hideImages)
        return markdown
    }
}

// Below from: https://github.com/nate-parrott/chattoys

public class FastHTMLProcessor {
    
    public enum URLMode: Equatable, Codable {
        /// Omits URLs (e.g. `[example]`)
        case omit
        /// Not implemented
        case shorten(prefix: String?)
        /// Retains URLs (e.g. `[example](http://example.com)`)
        case keep
        /// Truncates URLs (e.g. `[example](http://examp...)`)
        case truncate(Int)
    }
    
    struct MarkdownDoc {
        var bestLines = [String]()
        var normalLines = [String]()
        var worstLines = [String]()

        mutating func startNewLine(with score: Score) {
            switch score {
            case .best: bestLines.append("")
            case .normal: normalLines.append("")
            case .worst: worstLines.append("")
            }
        }
        
        mutating func appendInline(text: String, with score: Score) {
            switch score {
            case .best:
                bestLines.appendStringToLastItem(text)
            case .normal:
                normalLines.appendStringToLastItem(text)
            case .worst:
                worstLines.appendStringToLastItem(text)
            }
        }
        
        var asMarkdown: String {
            let allLines = bestLines + normalLines + worstLines
            let lines = allLines
                .compactMap { $0.nilIfEmptyOrJustWhitespace }
                .map { $0.trimmingCharacters(in: .whitespaces) }
            return lines.joined(separator: "\n").replacingOccurrences(of: FastHTMLProcessor.uncollapsedLinebreakToken, with: "\n")
        }
    }

    enum Score: Equatable {
        case best
        case normal
        case worst
    }

    let doc: HTMLDocument
    let baseURL: URL

    public init(url: URL, data: Data) throws {
        self.doc = try HTMLDocument(data: data)
        self.baseURL = url
    }

    public func markdown(urlMode: URLMode, hideJSONLD: Bool = false, hideImages: Bool = false) -> String {
        guard let body = doc.body else {
            return ""
        }
        var doc = MarkdownDoc()

        // First, look for special semantic JSON LD elements and move them to the front:
        //prependJSONLDData(urlMode: urlMode, toDoc: &doc)

        // Then, detect main content elements and conver them to markdown:
        let mainElements: [Fuzi.XMLElement] = {
            for sel in ["article", "main", "#app", "#content", "#site-content", "*[itemprop='mainEntity']"] {
                let matches = body.css(sel)
                if matches.count > 0 {
                    return Array(matches)
                }
            }
            return [body]
        }()
        for el in mainElements {
            traverse(element: el, doc: &doc, score: .normal, urlMode: urlMode, withinInline: false, hideImages: hideImages)
        }
        return doc.asMarkdown
    }

    private func prependJSONLDData(urlMode: URLMode, toDoc doc: inout MarkdownDoc) {
        // First, look for JSON in script tags:
        for script in self.doc.css("script[type='application/ld+json']") {
            if let text = script.stringValue.data(using: .utf8) {
                if let json = try? JSONSerialization.jsonObject(with: text, options: []) {
                    let processed = processJSONLD(inJSON: json, urlMode: urlMode)
                    if let encoded = try? JSONSerialization.data(withJSONObject: processed, options: []) {
                        if let str = String(data: encoded, encoding: .utf8) {
                            doc.bestLines.append(str)
                        }
                    }
                }
            }
        }
        // Then, look for items with [itemprop] attributes and prepend them like "key: value"
        for el in self.doc.css("*[itemprop]") {
            // Skip main entity; handle separately in HTML processing
            if let key = el.attr("itemprop"), key.lowercased() != "mainEntity" {
                if var value = el.stringValue.nilIfEmptyOrJustWhitespace ?? el.attr("content")?.nilIfEmptyOrJustWhitespace {
                    if value.isURL, let processed = processURL(value, urlMode: urlMode) {
                        value = processed
                    }
                    if value.nilIfEmptyOrJustWhitespace != nil {
                        doc.bestLines.append("\(key): \(value.collapseWhitespaceWithoutTrimming.leadingSpacesTrimmed.trailingSpacesTrimmed)")
                    }
                }
            }
        }
    }

    private func traverse(element: Fuzi.XMLElement, doc: inout MarkdownDoc, score parentScore: Score, urlMode: URLMode, withinInline: Bool, hideImages: Bool) {
        guard var score = self.score(element: element) else {
            return // skipped
        }
        if score == .normal {
            score = parentScore // inherit
        }
        let tagLower = element.tag?.lowercased() ?? ""

        // Handle images:
        if tagLower == "img" {
            if hideImages {
                return
            }
            if let alt = element.attr("alt")?.nilIfEmpty, let src = element.attr("src")?.nilIfEmpty {
                doc.startNewLine(with: score)
                doc.appendInline(text: "![\(alt.collapseWhitespace)]", with: score)
                if let urlStr = processURL(src, urlMode: urlMode) {
                    doc.appendInline(text: "(\(urlStr))", with: score)
                }
                doc.startNewLine(with: score)
            }
            return
        }

        var rule: Rule? = markdownRules[tagLower]
        if tagLower == "a" && urlMode == .omit {
            rule = nil // If urls are omitted, do not process `a` tags specially (but keep their inner content)
        }
        let inline = withinInline || (rule?.inline ?? false)
        if let rule, !rule.inline, !inline {
            doc.startNewLine(with: score)
        }
        if let prefix = rule?.prefix {
            doc.appendInline(text: prefix, with: score)
        }
        let childNodes = element.childNodes(ofTypes: [.Text, .Element])
        for (i, node) in childNodes.enumerated() {
            let isFirst = i == 0
            let isLast = i == childNodes.count - 1
            switch node.type {
            case .Text:
                var text: any StringProtocol = node.stringValue.collapseWhitespaceWithoutTrimming
                if isFirst {
                    text = text.leadingSpacesTrimmed
                }
                if isLast {
                    text = text.trailingSpacesTrimmed
                }
                doc.appendInline(text: String(text), with: score)
            case .Element:
                if let el = node as? Fuzi.XMLElement {
                    traverse(
                        element: el,
                        doc: &doc,
                        score: score,
                        urlMode: urlMode,
                        withinInline: inline,
                        hideImages: hideImages
                    )
                }
            default: ()
            }
        }
        if let suffix = rule?.suffix {
            doc.appendInline(text: suffix, with: score)
        }
        if tagLower == "a", let href = element.attr("href"), let processed = processURL(href, urlMode: urlMode) {
            doc.appendInline(text: "(\(processed))", with: score)
        }
        if let rule, !rule.inline, !inline {
            doc.startNewLine(with: score)
        }
    }

    private func processURL(_ raw: String, urlMode: URLMode) -> String? {
        if let url = URL(string: raw, relativeTo: baseURL), !["http", "https"].contains(url.scheme ?? "") {
            return nil
        }
        switch urlMode {
        case .shorten(let prefix):
            if let url = URL(string: raw, relativeTo: baseURL) {
                return shortenURL(url, prefix: prefix)
            }
            return nil
        case .keep, .omit, .truncate:
            if let url = URL(string: raw, relativeTo: baseURL) {
                return urlMode.process(url: url)
            }
            return nil
        }
    }

    // if nil, skip
    private func score(element: Fuzi.XMLElement) -> Score? {
        let tag = element.tag
        if tagsToSkip.contains(tag ?? "") {
            return nil
        }
        if element.attr("aria-hidden") == "true" {
            return nil
        }
        let role = element.attr("aria-role")
        let droppedAriaRoles = Set<String>([ "banner", "alert", "dialog", "navigation", "button" ])
        if droppedAriaRoles.contains(role ?? "") {
            return nil
        }
        let classes = element.attr("class")?.split(separator: " ") ?? []
        if classes.contains("nomobile") {
            // For wikipedia
            return nil
        }
        let style = element.attr("style") ?? ""
        if style.contains("display: none") || style.contains("display:none") {
            return nil
        }
        if tag == "article" || tag == "main" || element.attr("itemprop") == "mainEntity" || element.attr("id") == "content" || classes.contains("reviews-content") {
            return .best
        }
        return .normal
    }
    
    private let tagsToSkip = Set<String>([
        "script",
        "style",
        "svg",
        "link",
        "footer",
        "header",
        "form",
        "option",
        "nav",
        "object",
        "iframe",
        "dialog",
        "button",
    ])

    private struct Rule {
        var inline: Bool
        var prefix: String?
        var suffix: String?
        var establishesInlineContext: Bool? // https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Whitespace
    }
    private static let uncollapsedLinebreakToken = UUID().uuidString
    private var markdownRules: [String: Rule] = {
        let rules: [String: Rule] = [
            "h1": Rule(inline: false, prefix: "# "),
            "h2": Rule(inline: false, prefix: "## "),
            "h3": Rule(inline: false, prefix: "### "),
            "h4": Rule(inline: false, prefix: "#### "),
            "h5": Rule(inline: false, prefix: "##### "),
            "h6": Rule(inline: false, prefix: "###### "),
            "em": Rule(inline: true, prefix: "_", suffix: "_"),
            "i": Rule(inline: true, prefix: "_", suffix: "_"),
            "q": Rule(inline: true, prefix: "\"", suffix: "\""),
            "strong": Rule(inline: true, prefix: "**", suffix: "**"),
            "a": Rule(inline: true, prefix: "[", suffix: "]"),
            "br": Rule(inline: true, suffix: FastHTMLProcessor.uncollapsedLinebreakToken),
            "p": Rule(inline: false),
            "li": Rule(inline: false, prefix: "- "),
            "blockquote": Rule(inline: false, prefix: "> "),
            "code": Rule(inline: true, prefix: "`", suffix: "`"),
            "pre": Rule(inline: false),
            "hr": Rule(inline: false, suffix: "----"),
            "caption": Rule(inline: false),
//            "tr": Rule(inline: false, prefix: "| "),
//            "td": Rule(inline: true, suffix: " |"),
            "div": Rule(inline: false),
        ]
        return rules
    }()

    // MARK: - Shortening

    private var longToShortURLs = [URL: String]()
    public var shortToLongURLs = [String: URL]()
    private var shortURLCountsForDomains = [String: Int]()

    private func shortenURL(_ url: URL, prefix: String? = nil) -> String {
        if let short = longToShortURLs[url] {
            return short
        } else if var host = url.host {
            host.trimPrefix("www.")
            let count = shortURLCountsForDomains[host, default: 0] + 1
            let short = prefix != nil ? "\(host)/\(prefix!)/\(count)" : "\(host)/\(count)"
            shortURLCountsForDomains[host] = count
            longToShortURLs[url] = short
            shortToLongURLs[short] = url
            return short
        } else {
            return url.absoluteString
        }
    }
}

extension String {
    
    var nilIfEmpty: String? {
        return isEmpty ? nil : self
    }
    
    var nilIfEmptyOrJustWhitespace: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
    
    var collapseWhitespace: String {
        components(separatedBy: .whitespacesAndNewlines).filter({ $0.count > 0 }).joined(separator: " ")
    }
    
    var collapseWhitespaceWithoutTrimming: String {
        var results = [String]()
        var lastCompWasEmpty = false
        for comp in components(separatedBy: .whitespacesAndNewlines) {
            if comp == "" && !lastCompWasEmpty {
                results.append("")
            } else if comp != "" {
                results.append(comp)
            }
            lastCompWasEmpty = comp == ""
        }
        return results.joined(separator: " ")
    }
    
    var isURL: Bool {
        if starts(with: "https://") || starts(with: "http://"), firstIndex(where: { $0.isWhitespace }) == nil {
            return true
        }
        return false
    }
    
    func truncateTail(maxLen: Int) -> String {
        if count + 3 > maxLen {
            if maxLen <= 3 {
                return ""
            }
            return prefix(maxLen - 3) + "..."
        }
        return self
    }
}

extension FastHTMLProcessor.URLMode {
    func process(url: URL) -> String? {
        switch self {
        case .keep: return url.absoluteString
        case .omit: return nil
        case .truncate(let limit): return url.absoluteString.truncateTail(maxLen: limit)
        case .shorten: fatalError("Can't shorten HTMLs with this API")
        }
    }
}

private extension Array where Element == String {
    mutating func appendStringToLastItem(_ str: String) {
        if count > 0 {
            self[count - 1].append(str)
        } else {
            self.append(str)
        }
    }
}

extension StringProtocol {
    var trailingSpacesTrimmed: Self.SubSequence {
        var view = self[...]
        while view.last?.isWhitespace == true {
            view = view.dropLast()
        }
        return view
    }
    var leadingSpacesTrimmed: Self.SubSequence {
        var view = self[...]
        while view.first?.isWhitespace == true {
            view = view.dropFirst()
        }
        return view
    }
    var replaceNewlinesAndTabsWithSpaces: String {
        components(separatedBy: .whitespacesAndNewlines)
            .joined(separator: " ")
    }

}

func processJSONLD(inJSON json: Any, urlMode: FastHTMLProcessor.URLMode) -> Any {
    let skipKeys = ["@type", "@context"]
    if let dict = json as? [String: Any] {
        var newDict = [String: Any]()
        for (k, v) in dict {
            let newVal = processJSONLD(inJSON: v, urlMode: urlMode)
            if (newVal as? NSNull) != nil || (newVal as? String) == "" || skipKeys.contains(k) {
                // skip
            } else {
                newDict[k] = processJSONLD(inJSON: v, urlMode: urlMode)
            }
        }
        return newDict
    } else if let arr = json as? [Any] {
        return arr.map { processJSONLD(inJSON: $0, urlMode: urlMode) }
    } else if let str = json as? String {
        if str.isURL, let url = URL(string: str) {
            if let processed = urlMode.process(url: url) {
                return processed
            }
            return ""
        } else {
            return str
        }
    } else {
        return json
    }
}
