import Foundation
import GenKit

extension Tool {
    
    public static var searchWeb: Self =
        .init(
            type: .function,
            function: .init(
                name: "search_web",
                description: "Return a search query to search the web.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "query": .init(
                            type: .string,
                            description: "A web search query"
                        ),
                    ],
                    required: ["query"]
                )
            )
        )
    
    public struct SearchWeb: Codable {
        public var query: String
        
        public struct Response: Codable {
            public var instructions: String
            public var results: [WebSearchResult]
        }
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public static func call(_ toolCall: ToolCall) async -> [Message] {
            do {
                let obj = try decode(toolCall.function.arguments)
                let searchResponse = try await SearchManager.shared.search(query: obj.query)
                let response = Tool.SearchWeb.Response(
                    instructions: """
                        Do not perform another search unless the results below are unhelpful. Pick at least three of \
                        the most relevant results to browse the pages using the `\(Tool.generateWebBrowse.function.name)` \
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
                    metadata: ["label": "Searched the web for '\(obj.query)'"]
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
}
