import Foundation
import GenKit

extension Tool {
    
    public static var generateSuggestions: Self =
        .init(
            type: .function,
            function: .init(
                name: "suggested_prompts",
                description: """
                    Return a list of suggested replies related to the conversation. Remember, these are messages the
                    user can respond with. Think about what they might want to say.
                    """,
                parameters: .init(
                    type: .object,
                    properties: [
                        "prompts": .init(
                            type: .array,
                            description: "A list of short replies",
                            items: .init(type: .string, minItems: 2, maxItems: 3)
                        ),
                    ],
                    required: ["prompts"]
                )
            )
        )
    
    public struct GenerateSuggestions: Codable {
        public var prompts: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
