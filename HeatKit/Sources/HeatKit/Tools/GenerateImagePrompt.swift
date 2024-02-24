import Foundation
import GenKit

extension Tool {
    
    public static var generateImagePrompt: Self =
        .init(
            type: .function,
            function: .init(
                name: "generate_image",
                description: "Return a thoughtful, detailed image prompt.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "prompt": .init(type: .string, description: "A detailed prompt describing the image to generate."),
                    ],
                    required: ["prompt"]
                )
            )
        )
    
    public struct GenerateImagePrompt: Codable {
        public var prompt: String
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
