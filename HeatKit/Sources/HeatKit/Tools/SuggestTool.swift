import Foundation
import SharedKit
import GenKit

public struct SuggestTool {
    
    public struct Arguments: Codable {
        public var prompts: [String]
    }
    
    public static let function = Tool.Function(
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
    
    public static let message = Message(
        role: .user,
        content: "Suggest followup replies. Use the `\(function.name)` tool in your response."
    )
}

extension SuggestTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw ToolboxError.failedDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}
