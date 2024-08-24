// A conversation is an interaction between the user and a large language model (LLM). It has a title that helps
// set context for what the conversation is generally about and it has a history or messages.

import Foundation
import GenKit
import SharedKit
 
actor MessageStore {
    private var messages: [Message] = []
    
    func save(_ messages: [Message]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data = try encoder.encode(messages)
        try data.write(to: self.dataURL, options: [.atomic])
        self.messages = messages
    }
    
    func load() throws -> [Message] {
        let data = try Data(contentsOf: dataURL)
        let decoder = PropertyListDecoder()
        messages = try decoder.decode([Message].self, from: data)
        return messages
    }
    
    private var dataURL: URL {
        get throws {
            try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent("MessageData.plist")
        }
    }
}

@MainActor
@Observable
public final class MessagesProvider {
    public static let shared = MessagesProvider()
    
    public private(set) var messages: [Message] = []
    
    public func get(id: String) throws -> Message {
        guard let message = messages.first(where: { $0.id == id }) else {
            throw MessagesProviderError.notFound
        }
        return message
    }
    
    public func get(parentID: String) throws -> [Message] {
        messages.filter { $0.parent == parentID }
    }
    
    public func upsert(messages: [Message], parentID: String) async throws {
        for message in messages {
            try await upsert(message: message, parentID: parentID)
        }
    }
    
    public func upsert(message: Message, parentID: String) async throws {
        var message = message
        message.parent = parentID
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        try await save()
    }
    
    public func delete(id: String) async throws {
        messages.removeAll(where: { $0.id == id })
        try await save()
    }
    
    public func delete(parentID: String) async throws {
        messages.removeAll(where: { $0.parent == parentID })
        try await save()
    }
    
    public func reset() async throws {
        messages = []
        try await save()
    }
    
    // MARK: - Private
    
    private let conversationStore = ConversationStore()
    private let messageStore = MessageStore()
    
    private init() {
        Task {
            if BundleVersion.shared.isBundleVersionNew() {
                try await reset()
            } else {
                try await load()
            }
        }
    }
    
    private func load() async throws {
        self.messages = try await messageStore.load()
    }
    
    private func save() async throws {
        try await messageStore.save(messages)
    }
}

public enum MessagesProviderError: Error {
    case notFound
}
