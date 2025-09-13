import Foundation
import SharedKit
import GenKit

public struct WebBrowseTool {

    public struct Arguments: Codable {
        public var instructions: String
        public var title: String
        public var url: String
    }

    public struct Response: Codable, Identifiable {
        public let title: String
        public let url: String
        public let content: String?
        public let success: Bool

        public var id: String { url }
    }

    public static let function = Tool.Function(
        name: "web_browse",
        description: "Browse a webpage URL using the given instructions.",
        parameters: .object(
            properties: [
                "instructions": .string(description: "Instructions on how to scrape information from the webpage URL."),
                "title": .string(description: "A webpage title"),
                "url": .string(description: "A webpage URL"),
            ],
            required: ["instructions", "url", "title"]
        )
    )
}

extension WebBrowseTool.Arguments {

    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension WebBrowseTool {

    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function?.arguments ?? "")
            let summary = try await summarize(args)
            let label = "Read \(URL(string: args.url)?.host() ?? "")"
            return [.init(
                role: .tool,
                content: """
                <website>
                    <title>\(summary.title)</title>
                    <url>\(args.url)</url>
                    <summary>
                        \(summary.content ?? "No Content")
                    </summary>
                </website>
                """,
                toolCallID: toolCall.id,
                name: toolCall.function?.name,
                metadata: ["label": .string(label)]
            )]
        } catch {
            return [.init(
                role: .tool,
                content: """
                <error>
                    \(error.localizedDescription)
                </error>
                """,
                toolCallID: toolCall.id,
                name: toolCall.function?.name
            )]
        }
    }

    private static func summarize(_ args: Arguments) async throws -> Response {
        let (service, model) = try await API.shared.preferredSummarizationService()
        do {
            let summary = try await WebBrowseSession.shared.generateSummary(
                service: service,
                model: model,
                url: args.url,
                instructions: args.instructions
            )
            return .init(
                title: args.title,
                url: args.url,
                content: summary,
                success: true
            )
        } catch {
            return .init(
                title: args.title,
                url: args.url,
                content: """
                <error>
                    \(error.localizedDescription)
                </error>
                """,
                success: false
            )
        }
    }
}
