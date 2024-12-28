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
        case web
        case image
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
                    description: "A kind of search (e.g. web or image)",
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
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension WebSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            
            switch args.kind {
            case .web:
                let searchResponse = try await WebSearchSession.shared.search(query: args.query)
                let results = Array(searchResponse.results.prefix(10)).map {
                    """
                        <result>
                            <title>\($0.title ?? "No title")</title>
                            <url>\($0.url)</url>
                            <description>\($0.description ?? "No description")</description>
                        </result>
                    """
                }
                return [.init(
                    role: .tool,
                    content: PromptTemplate(BrowseSearchResultsInstructions, with: [
                        "QUERY": args.query,
                        "RESULTS": results.joined(separator: "\n"),
                    ]),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: .init(["label": "Searched web for '\(args.query)'"])
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
                let content = String(data: data, encoding: .utf8)
                return [.init(
                    role: .tool,
                    content: content,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: .init(["label": "Searched web images for '\(args.query)'"])
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
