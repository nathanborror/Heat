import Foundation
import SharedKit
import GenKit

public struct WebSearchTool {

    public struct Arguments: Codable {
        public var query: String
        public var kind: Kind
    }
    
    public struct Response: Codable {
        public var kind: Kind
        public var instructions: String
        public var results: [WebSearchResult]
    }
    
    public enum Kind: String, Codable, CaseIterable {
        case website
        case image
        case news
    }
    
    public static let function = Tool.Function(
        name: "web_search",
        description: "Return a search query used to search the web for website only or image only results.",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "query": .init(
                    type: .string,
                    description: "A web search query"
                ),
                "kind": .init(
                    type: .string,
                    description: "A kind of search (e.g. website or image)",
                    enumValues: Kind.allCases.map { $0.rawValue }
                ),
            ],
            required: ["query", "kind"]
        )
    )
}

extension WebSearchTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw KitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension WebSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            
            switch args.kind {
            case .website:
                let searchResponse = try await WebSearchSession.shared.search(query: args.query)
                let results = Array(searchResponse.results.prefix(10)).map {
                    """
                        <result>
                            <title>\($0.title ?? "No title")</title>
                            <url>\($0.url)</url>
                            <description>\($0.description ?? "No description")</description>
                        </result>
                    """
                }.joined(separator: "\n")
                return [.init(
                    role: .tool,
                    content: """
                    Select relevant website results, scrape their page and summarize it. Use the <search_results> \
                    below to select at least 3 results to scrape and summarize. Choose the most relevant and diverse \
                    sources that would provide comprehensive information about the search query, "\(args.query)". \
                    
                    Consider factors such as:
                       - Relevance to the search query
                       - Credibility of the source
                       - Diversity of perspectives
                       - Recency of the information
                    
                    For each selected result, provide a summary of the key information. Your summary should:
                       - Be concise but informative (aim for 3-5 sentences per result)
                       - Capture the main points relevant to the search query
                       - Avoid unnecessary details or tangential information
                       - Use your own words, do not copy text directly from the sources
                    
                    Remember to select at least 3 results, but you may choose more if you find additional sources that \
                    provide valuable and diverse information. Ensure that your summaries are objective and accurately \
                    represent the content of each source.
                    
                    Use the `\(Toolbox.browseWeb.name)` tool.
                    
                    <search_results>
                    \(results)
                    </search_results>
                    """,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched web for '\(args.query)'"]
                )]
            case .news:
                let searchResponse = try await WebSearchSession.shared.searchNews(query: args.query)
                let results = Array(searchResponse.results.prefix(10)).map {
                    """
                        <result>
                            <title>\($0.title ?? "No title")</title>
                            <url>\($0.url)</url>
                            <description>\($0.description ?? "No description")</description>
                        </result>
                    """
                }.joined(separator: "\n")
                return [.init(
                    role: .tool,
                    content: """
                    Select relevant website results, scrape their page and summarize it. Use the <search_results> \
                    below to select at least 3 results to scrape and summarize. Choose the most relevant and diverse \
                    sources that would provide comprehensive information about the search query, "\(args.query)". \
                    
                    Consider factors such as:
                       - Relevance to the search query
                       - Credibility of the source
                       - Diversity of perspectives
                       - Recency of the information
                    
                    For each selected result, provide a summary of the key information. Your summary should:
                       - Be concise but informative (aim for 3-5 sentences per result)
                       - Capture the main points relevant to the search query
                       - Avoid unnecessary details or tangential information
                       - Use your own words, do not copy text directly from the sources
                    
                    Remember to select at least 3 results, but you may choose more if you find additional sources that \
                    provide valuable and diverse information. Ensure that your summaries are objective and accurately \
                    represent the content of each source.
                    
                    Use the `\(Toolbox.browseWeb.name)` tool.
                    
                    <news_search_results>
                    \(results)
                    </news_search_results>
                    """,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched web news for '\(args.query)'"]
                )]
            case .image:
                let searchResponse = try await WebSearchSession.shared.searchImages(query: args.query)
                let response = Response(
                    kind: .image,
                    instructions: """
                        Search complete. Showing \(searchResponse.results.count) images. DO NOT repeat any of the \
                        image URLs here. Let the user know you found \(searchResponse.results.count) images, each
                        one will take the user to the website it originates from. Do not respond with any more URLs.
                        """,
                    results: Array(searchResponse.results.prefix(10))
                )
                let data = try JSONEncoder().encode(response)
                return [.init(
                    role: .tool,
                    content: String(data: data, encoding: .utf8),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched web images for '\(args.query)'"]
                )]
            }
            
        } catch {
            return [.init(
                role: .tool,
                content: """
                <error>
                    \(error.localizedDescription)
                </error>
                """,
                toolCallID: toolCall.id,
                name: toolCall.function.name
            )]
        }
    }
}
