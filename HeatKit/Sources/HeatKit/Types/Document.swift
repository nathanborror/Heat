import Foundation
import SharedKit
import GenKit

public struct Document: Codable, Sendable {
    public var title: String?
    public var text: String
    public var attributes: [Attribute]
    public var state: State

    public enum State: Codable, Sendable {
        case processing
        case streaming
        case suggesting
        case none
    }

    public struct Attribute: Codable, Sendable {
        public var key: String
        public var value: String
        public var location: Int
        public var length: Int

        public init(key: String, value: String, location: Int, length: Int) {
            self.key = key
            self.value = value
            self.location = location
            self.length = length
        }
    }

    public init(title: String? = nil, text: String = "", attributes: [Attribute] = [], state: State = .none) {
        self.title = title
        self.text = text
        self.attributes = attributes
        self.state = state
    }

    func apply(document: Document) -> Document {
        var existing = self
        existing.title = document.title
        existing.text = document.text
        existing.attributes = document.attributes
        existing.state = document.state
        return existing
    }

    public static var empty: Self {
        .init()
    }
}

extension Document {

    public func encodeMessages() -> [Message] {
        var out: [Message] = []

        // Filter out roles and sort them by location
        let roles = attributes
            .filter { $0.key == "Attachment.Role" }
            .sorted { $0.location < $1.location}

        // Determine message ranges
        for (i, role) in roles.enumerated() {
            if (i+1) < roles.count {
                let location = role.location+role.length
                let length = roles[i+1].location
                let message = extract(from: text, location: location, length: length)
                out.append(.init(role: encode(role: role.value), content: message))
            } else {
                let location = role.location+role.length
                let length = text.count
                let message = extract(from: text, location: location, length: length)
                out.append(.init(role: encode(role: role.value), content: message))
            }
        }
        return out
    }

    private func encode(role: String) -> Message.Role {
        switch role.lowercased() {
        case "user":
            return .user
        case "assistant":
            return .assistant
        case "system":
            return .system
        default:
            return .user
        }
    }

    private func extract(from text: String, location: Int, length: Int, trimWhitespace: Bool = true) -> String {
        let startIndex = text.index(text.startIndex, offsetBy: location)
        let endIndex = text.index(text.startIndex, offsetBy: length)
        let out = String(text[startIndex..<endIndex])
        if trimWhitespace {
            return out.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return out
    }
}
