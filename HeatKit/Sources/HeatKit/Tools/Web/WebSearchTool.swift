import Foundation
import SharedKit
import GenKit

public struct WebSearchTool {

    public struct Arguments: Codable {
        public var query: String
    }
    
    public struct Response: Codable {
        public var instructions: String
        public var results: [WebSearchResult]
    }
    
    public static let function = Tool.Function(
        name: "web_search",
        description: "Return a search query to search the web.",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "query": .init(type: .string, description: "A web search query"),
            ],
            required: ["query"]
        )
    )
}

extension WebSearchTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw HeatKitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension WebSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            let searchResponse = try await WebSearchSession.shared.search(query: args.query)
            let response = Response(
                instructions: """
                    Do not perform another search unless the results below are unhelpful. Pick at least three of \
                    the most relevant results to browse the pages using the `\(Toolbox.browseWeb.name)` \
                    function. Ignore all 'youtube.com' results. When you have finished browsing the results prepare \
                    a response that compares and contrasts the information you've gathered. Remember to use citations.
                    """,
                results: searchResponse.results
            )
            let data = try JSONEncoder().encode(response)
            return [.init(
                role: .tool,
                content: String(data: data, encoding: .utf8),
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Searched the web for '\(args.query)'"]
            )]
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
