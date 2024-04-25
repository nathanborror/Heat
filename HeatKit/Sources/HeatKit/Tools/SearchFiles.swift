import Foundation
import GenKit

extension Tool {
    
    public static var searchFiles: Self =
        .init(
            type: .function,
            function: .init(
                name: "search_files",
                description: """
                    Searches the local filesystem for applications, files, emails, PDFs, events, contacts and images.
                    """,
                parameters: .init(
                    type: .object,
                    properties: [
                        "query": .init(type: .string, description: "A search query"),
                        "kind": .init(type: .string, description: "An optional filter to restrict what kind of files to return.", enumValues: SpotlightManager.Kind.allCases.map { $0.rawValue })
                    ],
                    required: ["query"]
                )
            )
        )
    
    public struct SearchFiles: Codable {
        public var query: String
        public var kind: String?
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
}
