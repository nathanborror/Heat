import Foundation
import SharedKit
import SwiftData
import GenKit

public struct MemoryTool {

    public struct Arguments: Codable {
        public var items: [String]
    }
    
    public static let function = Tool.Function(
        name: "remember",
        description: """
            Return a list of useful things to remember about the user for future conversations. Some examples
            include names, important dates, facts about the user, and interests. Basically anything meaninful
            that would help relate to the user more.
            """,
        parameters: JSONSchema(
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
}

extension MemoryTool.Arguments {
    
    public init(_ arguments: String) throws {
        guard let data = arguments.data(using: .utf8) else {
            throw HeatKitError.failedtoolDecoding
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
}

extension MemoryTool {
    
    public static func handle(_ toolCall: ToolCall) async -> [Message] {
        do {
            let args = try Arguments(toolCall.function.arguments)
            let container = try ModelContainer(for: Memory.self)
            
            Task { @MainActor in
                args.items.forEach {
                    container.mainContext.insert(Memory(content: $0))
                }
            }
            
            return [.init(
                role: .tool,
                content: "Saved to memory.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": args.items.count == 1 ? "Stored memory" : "Stored \(args.items.count) memories"]
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
