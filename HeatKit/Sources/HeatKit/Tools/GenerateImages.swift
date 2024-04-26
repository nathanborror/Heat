import Foundation
import GenKit

extension Tool {
    
    public static var generateImages: Self =
        .init(
            type: .function,
            function: .init(
                name: "generate_images",
                description: "Return thoughtful, detailed image prompts.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "prompts": .init(
                            type: .array,
                            description: "A list of detailed prompts describing images to generate.",
                            items: .init(type: .string, minItems: 1, maxItems: 9)
                        ),
                    ],
                    required: ["prompts"]
                )
            )
        )
    
    public struct GenerateImages: Codable {
        public var prompts: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
