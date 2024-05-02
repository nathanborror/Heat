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
        
        public struct Response: Codable, Identifiable {
            public let title: String?
            public let url: String
            public let content: String?
            public let success: Bool
            
            public var id: String { url }
        }
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
        
        public static func call(_ toolCall: ToolCall) async -> [Message] {
            do {
                let obj = try decode(toolCall.function.arguments)
                let sources = try await makeWebBrowseSummary(webpage: obj)
                let sourcesData = try JSONEncoder().encode(sources)
                let sourcesString = String(data: sourcesData, encoding: .utf8)
                let label = "Read \(URL(string: obj.url)?.host() ?? "")"
                return [.init(
                    role: .tool,
                    content: sourcesString,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": label]
                )]
            } catch {
                return [.init(
                    role: .tool,
                    content: "Tool Failed: \(error.localizedDescription)",
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )]
            }
        }
        
        private static func makeWebBrowseSummary(webpage: Tool.GenerateWebBrowse) async throws -> Tool.GenerateWebBrowse.Response {
            let summarizationService = try Store.shared.preferredSummarizationService()
            let summarizationModel = try Store.shared.preferredSummarizationModel()
            
            do {
                let summary = try await BrowserManager().generateSummary(service: summarizationService, model: summarizationModel, url: webpage.url)
                return .init(
                    title: webpage.title,
                    url: webpage.url,
                    content: summary,
                    success: true
                )
            } catch {
                return .init(
                    title: webpage.title,
                    url: webpage.url,
                    content: nil,
                    success: false
                )
            }
        }
    }
}
