import Foundation
import GenKit

extension Tool {
    
    public static var generateTitle: Self {
        .init(
            type: .function,
            function: .init(
                name: "title_maker",
                description: """
                    Returns a title if there is a clear topic of conversation. The title should be under 4 words.
                    Nothing is returned if there is no topic or if the conversation is just greetings.
                    """,
                parameters: .init(
                    type: .object,
                    properties: [
                        "title": .init(type: .string, description: "A short title")
                    ]
                )
            )
        )
    }

    public struct GenerateTitle: Codable {
        public var title: String?
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
