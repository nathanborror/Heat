import Foundation
import GenKit

extension Tool {
    
    public static var generateWebBrowse: Self =
        .init(
            type: .function,
            function: .init(
                name: "browse_web",
                description: "Return a list of URLs that should be browsed.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "instructions": .init(type: .string, description: "Instructions to perform on the given URLs. Default to summarization."),
                        "urls": .init(type: .array, description: "A list of URLs", items: .init(type: .string, minItems: 1)),
                    ],
                    required: ["instructions", "urls"]
                )
            )
        )
    
    public struct GenerateWebBrowse: Codable {
        public var instructions: String
        public var urls: [String]
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public struct Source: Codable, Identifiable {
            public let url: String
            public let summary: String
            
            public var id: String { url }
        }
    }
}
