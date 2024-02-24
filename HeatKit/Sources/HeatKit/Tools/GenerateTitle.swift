import Foundation
import GenKit
import OpenAI

extension Tool {
    
    public static var generateTitle: Self {
        .init(
            type: .function,
            function: .init(
                name: "title_maker",
                description: "Returns a title that represents the main topic of conversation",
                parameters: JSONSchema(
                    type: .object,
                    properties: [
                        "title": .init(
                            type: .string,
                            description: "A short title"
                        )
                    ],
                    required: ["title"]
                )
            )
        )
    }

    public struct GenerateTitle: Codable {
        var title: String
        
        public func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
