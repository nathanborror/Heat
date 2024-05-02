import Foundation
import GenKit

extension Tool {
    
    public static var searchCalendar: Self =
        .init(
            type: .function,
            function: .init(
                name: "search_calendar",
                description: """
                    Searches the user's calendar. You must always include a `start` and an `end` date.
                    """,
                parameters: .init(
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
        )
    
    public struct SearchCalendar: Codable {
        public var start: String
        public var end: String
        public var query: String?
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public static func call(_ toolCall: ToolCall) async -> [Message] {
            do {
                let obj = try decode(toolCall.function.arguments)
                let events = try CalendarManager.shared.events(between: obj.start, end: obj.end)
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
}
