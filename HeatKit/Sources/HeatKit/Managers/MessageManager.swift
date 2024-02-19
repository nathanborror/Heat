import Foundation
import OSLog
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    public typealias CallBack = (MessageManager) -> Void
    public typealias MessageCallback = (Message) -> Void
    
    public private(set) var messages: [Message]
    public private(set) var error: Error?
    
    private var filteredMessages: [Message] {
        messages.filter { $0.kind != .error }
    }
    
    public init(messages: [Message] = []) {
        self.messages = messages
        self.error = nil
    }
    
    @discardableResult
    public func append(message: Message, callback: MessageCallback? = nil) async -> Self {
        messages.append(message)
        await MainActor.run { callback?(message) }
        return self
    }
    
    @discardableResult
    public func generate(service: ChatService, model: String, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages)
            let message = try await service.completion(request: req)
            await append(message: message)
            await MainActor.run { callback?(message) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: ChatService, model: String, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages)
            try await service.completionStream(request: req) { message in
                let message = apply(delta: message)
                await MainActor.run { callback?(message) }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: VisionService, model: String, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            let message = try await service.completion(request: req)
            await append(message: message)
            await MainActor.run { callback?(message) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: VisionService, model: String, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            try await service.completionStream(request: req) { message in
                let message = apply(delta: message)
                await MainActor.run { callback?(message) }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func manage(callback: CallBack) async -> Self {
        await MainActor.run { callback(self) }
        return self
    }

    // MARK: - Private
    
    private func apply(delta message: Message) -> Message {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            let newMessage = messages[index].apply(message)
            messages[index] = newMessage
            return newMessage
        } else {
            messages.append(message)
            return message
        }
    }
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("MessageManager Error: \(error, privacy: .public)")
            self.error = error
        }
    }
}
