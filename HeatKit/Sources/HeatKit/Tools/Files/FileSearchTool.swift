import Foundation
import SharedKit
import GenKit

struct FileSearchTool {
    
    public struct Arguments: Codable {
        public var query: String
        public var kind: String?
    }
    
    public static let function = Tool.Function(
        name: "search_files",
        description: """
            Searches the local filesystem for applications, files, emails, PDFs, events, contacts and images.
            """,
        parameters: JSONSchema(
            type: .object,
            properties: [
                "query": .init(
                    type: .string,
                    description: "A search query"
                ),
                "kind": .init(
                    type: .string,
                    description: "An optional filter to restrict what kind of files to return.",
                    enumValues: SpotlightSession.Kind.allCases.map { $0.rawValue }
                )
            ],
            required: ["query"]
        )
    )
}

extension FileSearchTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension FileSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            let results = try await SpotlightSession.shared.query(args.query, kind: .init(rawValue: args.kind ?? ""))
            return [.init(
                role: .tool,
                content: results.joined(separator: "\n"),
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Searched files for '\(args.query)'"]
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
