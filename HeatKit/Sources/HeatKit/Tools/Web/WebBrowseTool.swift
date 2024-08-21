import Foundation
import SharedKit
import GenKit

public struct WebBrowseTool {

    public struct Arguments: Codable {
        public var instructions: String
        public var title: String?
        public var url: String
    }
    
    public struct Response: Codable, Identifiable {
        public let title: String?
        public let url: String
        public let content: String?
        public let success: Bool
        
        public var id: String { url }
    }
    
    public static let function = Tool.Function(
        name: "browse_web",
        description: "Browse a webpage URL using the given instructions.",
        parameters: JSONSchema(
            type: .object,
            properties: [
                "instructions": .init(
                    type: .string,
                    description: "Instructions to perform on the given URLs. Default to summarization."
                ),
                "title": .init(
                    type: .string,
                    description: "A webpage title"
                ),
                "url": .init(
                    type: .string,
                    description: "A webpage URL"
                ),
            ],
            required: ["instructions", "url"]
        )
    )
}

extension WebBrowseTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw KitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension WebBrowseTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            let sources = try await summarize(args)
            let sourcesData = try JSONEncoder().encode(sources)
            let sourcesString = String(data: sourcesData, encoding: .utf8)
            let label = "Read \(URL(string: args.url)?.host() ?? "")"
            return [.init(
                role: .tool,
                content: sourcesString,
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": label]
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
    
    private static func summarize(_ args: Arguments) async throws -> Response {
        let summarizationService = try await PreferencesProvider.shared.preferredSummarizationService()
        let summarizationModel = try await PreferencesProvider.shared.preferredSummarizationModel()
        
        do {
            let summary = try await WebBrowseSession.shared.generateSummary(service: summarizationService, model: summarizationModel, url: args.url)
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
                content: nil,
                success: false
            )
        }
    }
}
