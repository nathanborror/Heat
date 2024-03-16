import Foundation
import GenKit

extension Tool {
    
    public static var generateWebBrowse: Self =
        .init(
            type: .function,
            function: .init(
                name: "browse_web",
                description: "Browse a list of webpages using the given instructions.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "instructions": .init(
                            type: .string,
                            description: "Instructions to perform on the given URLs. Default to summarization."
                        ),
                        "webpages": .init(
                            type: .array,
                            description: "A list of webpages",
                            items: .init(
                                type: .object,
                                properties: [
                                    "url": .init(type: .string, description: "Webpage url"),
                                    "title": .init(type: .string, description: "Webpage title"),
                                ]
                            ),
                            required: ["url"]
                        ),
                    ],
                    required: ["instructions", "webpages"]
                )
            )
        )
    
    public struct GenerateWebBrowse: Codable {
        public var instructions: String
        public var webpages: [Webpage]
        
        public struct Webpage: Codable {
            public var url: String
            public var title: String?
        }
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public struct Source: Codable, Identifiable {
            public let title: String
            public let url: String
            public let summary: String
            
            public var id: String { url }
        }
    }
}
