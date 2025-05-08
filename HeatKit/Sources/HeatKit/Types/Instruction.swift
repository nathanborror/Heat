import Foundation
import GenKit
import SharedKit

public struct Instruction: Codable, Sendable {
    public var kind: Kind
    public var instructions: String
    public var context: [String: String]    // Context variables injected into the instructions
    public var tags: [String]               // XML tags expected in the output
    public var toolIDs: Set<String>

    public enum Kind: String, Codable, Sendable, CaseIterable {
        case system     // used as the system prompt for a conversation
        case template   // prompt templates that typically has variables to populate
        case task       // used to complete a task like generating a title or suggestions
    }

    public init(kind: Kind, instructions: String, context: [String: String] = [:], tags: [String] = [], toolIDs: Set<String> = []) {
        self.kind = kind
        self.instructions = instructions
        self.context = context
        self.tags = tags
        self.toolIDs = toolIDs
    }
}
