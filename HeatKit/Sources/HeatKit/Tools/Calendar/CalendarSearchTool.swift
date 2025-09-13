import Foundation
import SharedKit
import GenKit

public struct CalendarSearchTool {
    
    public struct Arguments: Codable {
        public var start: Date
        public var end: Date
        public var query: String?
    }
    
    public static let function = Tool.Function(
        name: "calendar_search",
        description: """
            Searches the user's calendar. You must always include a `start` and an `end` date.
            """,
        parameters: .object(
            properties: [
                "start": .string(
                    description: "A start date and time. (Example: 2024-01-02T00:00)",
                    format: "date-time"
                ),
                "end": .string(
                    description: "An end date and time. (Example: 2024-02-02T23:59)",
                    format: "date-time"
                ),
                "query": .string(description: "An optional search query"),
            ],
            required: ["start", "end"]
        )
    )
    
    public static let dateFormat = "yyyy-MM-dd'T'HH:mm"
    
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            return Date(string: string, format: dateFormat) ?? .now
        })
        return decoder
    }()
}

extension CalendarSearchTool.Arguments {
    
    public init(_ arguments: String?) throws {
        guard let arguments, let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try CalendarSearchTool.decoder.decode(Self.self, from: data)
    }
}

extension CalendarSearchTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function?.arguments)
            let events = try await CalendarSession.shared.events(between: args.start, end: args.end)
            return [.init(
                role: .tool,
                content: events.map { $0.title }.joined(separator: "\n"),
                toolCallID: toolCall.id,
                name: toolCall.function?.name,
                metadata: ["label": .string("Found \(events.count) calendar items.")]
            )]
        } catch {
            return [.init(
                role: .tool,
                content: "You do not have calendar access. Tell the user to open Preferences and navigate to Permissions to enable calendar access.",
                toolCallID: toolCall.id,
                name: toolCall.function?.name,
                metadata: ["label": .string("Error accessing calendar")]
            )]
        }
    }
}
