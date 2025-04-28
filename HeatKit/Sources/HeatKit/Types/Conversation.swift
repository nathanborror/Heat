import Foundation
import GenKit
import SharedKit

public struct Conversation: Codable, Sendable {
    public var instructions: String
    public var suggestions: [String]
    public var toolIDs: Set<String>
    public var state: State
    public var messages: [Message]

    public enum State: Codable, Sendable {
        case processing
        case streaming
        case suggesting
        case none
    }

    public init(instructions: String = "", suggestions: [String] = [], toolIDs: Set<String> = [], state: State = .none, messages: [Message] = []) {
        self.instructions = instructions
        self.suggestions = suggestions
        self.toolIDs = toolIDs
        self.state = state
        self.messages = messages
    }
}
