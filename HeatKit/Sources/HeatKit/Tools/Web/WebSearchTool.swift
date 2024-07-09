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
    
    public static func handle(_ toolCall: ToolCall, response: WebSearchResponse) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            switch args.kind {
            case .website:
                let content = Response(
                    kind: .website,
                    instructions: """
                        Pick three or more of the most relevant results to browse using the `\(Toolbox.browseWeb.name)` \
                        function. Ignore all 'youtube.com' results. When you have finished browsing the results \
                        prepare a response that compares and contrasts the information you've gathered. Use citations.
                        Always browse results.
                        """,
                    results: response.results
                )
                let data = try JSONEncoder().encode(content)
                return [.init(
                    role: .tool,
                    content: String(data: data, encoding: .utf8),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched web for '\(args.query)'"]
                )]
            case .news:
                let content = Response(
                    kind: .news,
                    instructions: """
                        Pick three or more of the most relevant results to browse using the `\(Toolbox.browseWeb.name)` \
                        function. Ignore all 'youtube.com' results. When you have finished browsing the results \
                        prepare a response that compares and contrasts the information you've gathered. Use citations.
                        Always browse results.
                        """,
                    results: response.results
                )
                let data = try JSONEncoder().encode(content)
                return [.init(
                    role: .tool,
                    content: String(data: data, encoding: .utf8),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched web news for '\(args.query)'"]
                )]
            case .image:
                let content = Response(
                    kind: .image,
                    instructions: """
                        DO NOT repeat these images in Markdown.
                        """,
                    results: response.results
                )
                let data = try JSONEncoder().encode(content)
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
                content: "Tool Failed: \(error.localizedDescription)",
                toolCallID: toolCall.id,
                name: toolCall.function.name
            )]
        }
    }
}
