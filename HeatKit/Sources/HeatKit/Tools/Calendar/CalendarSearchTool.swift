import Foundation
import SharedKit
import GenKit

public struct CalendarSearchTool {
    
    public struct Arguments: Codable {
        public var start: String
        public var end: String
        public var query: String?
    }
    
    public static let function = Tool.Function(
        name: "search_calendar",
        description: """
            Searches the user's calendar. You must always include a `start` and an `end` date.
            """,
        parameters: JSONSchema(
            type: .object,
            properties: [
                "start": .init(
                    type: .string,
                    description: "A start date. (Example: 2024-01-02)",
                    format: "date"
                ),
                "end": .init(
                    type: .string,
                    description: "An end date. (Example: 2024-02-02)",
                    format: "date"
                ),
                "query": .init(
                    type: .string,
                    description: "An optional search query"
                ),
            ],
            required: ["start", "end"]
        )
    )
}

extension CalendarSearchTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw KitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension CalendarSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            let events = try CalendarSession.shared.events(between: args.start, end: args.end)
            return [.init(
                role: .tool,
                content: events.map { $0.title }.joined(separator: "\n"),
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Found \(events.count) calendar items."]
            )]
        } catch {
            return [.init(
                role: .tool,
                content: "You do not have calendar access. Tell the user to open Preferences and navigate to Permissions to enable calendar access.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Error accessing calendar"]
            )]
        }
    }
}
