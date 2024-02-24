import Foundation
import GenKit

extension Tool {
    
    public static var generateSuggestions: Self =
        .init(
            type: .function,
            function: .init(
                name: "suggested_user_replies",
                description: "Return a list of three suggested user replies based on the last message sent by the assistant.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "suggestions": .init(type: .array, description: "A list of short reply suggestions.", items: .init(type: .string, minItems: 2, maxItems: 4)),
                    ],
                    required: ["suggestions"]
                )
            )
        )
    
    public struct GenerateSuggestions: Codable {
        public var suggestions: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
