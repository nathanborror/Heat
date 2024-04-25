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
                        "start": .init(type: .string, description: "A start date. (Example: 2024-01-02)", format: "date"),
                        "end": .init(type: .string, description: "An end date. (Example: 2024-02-02)", format: "date"),
                        "query": .init(type: .string, description: "An optional search query"),
                    ],
                    required: ["start_date", "end_date"]
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
    }
}
