import Foundation
import GenKit
import SharedKit

public struct Instruction: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var name: String
    public var instructions: String
    public var context: [String: String]    // Context variables that will be injected into the instructions prompt
    public var tags: [String]               // XML tags that are expected in the output
    public var toolIDs: Set<String>

    public enum Kind: String, Codable, Sendable, CaseIterable {
        case assistant
        case prompt
    }

    public init(id: String, kind: Kind, name: String, instructions: String, context: [String: String] = [:], tags: [String] = [],
                toolIDs: Set<String> = []) {
        self.id = id
        self.kind = kind
        self.name = name
        self.instructions = instructions
        self.context = context
        self.tags = tags
        self.toolIDs = toolIDs
    }
}
