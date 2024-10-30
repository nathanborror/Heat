import Foundation
import Fuzi

public struct GoogleSearch: WebSearch, WebImageSearch {

    let host = "https://www.google.com/search"

    public func search(web query: String) async throws -> WebSearchResponse {
        let userAgent = WebSearchUserAgent.desktop

        var urlComponents = URLComponents(string: host)!
        urlComponents.queryItems = [
            .init(name: "q", value: query),
        ]
        
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

    public func search(images query: String) async throws -> WebSearchResponse {
        let userAgent = WebSearchUserAgent.mobile

        var urlComponents = URLComponents(string: host)!
        urlComponents.queryItems = [
            .init(name: "q", value: query),
            .init(name: "tbm", value: "isch"), // to be matched = image search
            .init(name: "gbv", value: "1"), // google basic version = 1 (no js)
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpShouldHandleCookies = false
        request.setValue(userAgent.rawValue, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .returnCacheDataElseLoad

        let (data, response) = try await session.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw WebSearchError.invalidHTML
        }
        let baseURL = response.url ?? urlComponents.url!
        let resp = try extractImageResults(html: html, baseURL: baseURL, query: query)
        return resp
    }

    private let session = {
        let memoryCapacity = 500 * 1024 * 1024 // 500 MB
        let diskCapacity = 500 * 1024 * 1024   // 500 MB
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let diskPath = cachesURL.appendingPathComponent("GoogleSearchCache").path

        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: diskPath)
        URLCache.shared = cache

        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy

        return URLSession(configuration: configuration)
    }()
}

extension GoogleSearch {

    private func extractResults(html: String, baseURL: URL, query: String) throws -> WebSearchResponse {
        let doc = try Fuzi.HTMLDocument(string: html)
        guard let main = doc.css("#main").first else {
            throw WebSearchError.missingElement("#main")
        }
        var results = [WebSearchResult]()
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
}
