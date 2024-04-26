import Foundation
import GenKit

extension Tool {
    
    public static var generateMemory: Self =
        .init(
            type: .function,
            function: .init(
                name: "remember",
                description: """
                    Return a list of useful things to remember about the user for future conversations. Some examples
                    include names, important dates, facts about the user, and interests. Basically anything meaninful
                    that would help relate to the user more.
                    """,
                parameters: .init(
                    type: .object,
                    properties: [
                        "items": .init(
                            type: .array,
                            description: "A short description of what to remember.",
                            items: .init(type: .string)
                        ),
                    ],
                    required: ["items"]
                )
            )
        )
    
    public struct GenerateMemory: Codable {
        public var items: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
