import Foundation
import SwiftData
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
        
        public static func call(_ toolCall: ToolCall) async -> [Message] {
            do {
                let obj = try decode(toolCall.function.arguments)
                let container = try ModelContainer(for: Memory.self)
                
                Task { @MainActor in
                    obj.items.forEach {
                        container.mainContext.insert(Memory(content: $0))
                    }
                }
                
                return [.init(
                    role: .tool,
                    content: "Saved to memory.",
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": obj.items.count == 1 ? "Stored memory" : "Stored \(obj.items.count) memories"]
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
    }
}
