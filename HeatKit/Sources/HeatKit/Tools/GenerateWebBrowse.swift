import Foundation
import GenKit

extension Tool {
    
    public static var generateWebBrowse: Self =
        .init(
            type: .function,
            function: .init(
                name: "browse_web",
                description: "Browse a webpage URL using the given instructions.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "instructions": .init(
                            type: .string,
                            description: "Instructions to perform on the given URLs. Default to summarization."
                        ),
                        "title": .init(
                            type: .string,
                            description: "A webpage title"
                        ),
                        "url": .init(
                            type: .string,
                            description: "A webpage URL"
                        ),
                    ],
                    required: ["instructions", "url"]
                )
            )
        )
    
    public struct GenerateWebBrowse: Codable {
        public var instructions: String
        public var title: String?
        public var url: String
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public struct Source: Codable, Identifiable {
            public let title: String?
            public let url: String
            public let content: String?
            public let success: Bool
            
            public var id: String { url }
        }
    }
}
