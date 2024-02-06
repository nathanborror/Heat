import Foundation
import OSLog
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    
    private var messages: [Message]
    private var error: Error?
    
    private var filteredMessages: [Message] {
        messages.filter { $0.kind != .error }
    }
    
    public init(messages: [Message] = []) {
        self.messages = messages
        self.error = nil
    }
    
    @discardableResult
    public func append(message: Message) -> Self {
        messages.append(message)
        return self
    }
    
    @discardableResult
    public func generate(service: ChatService, model: String) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages)
            let message = try await service.completion(request: req)
            return append(message: message)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: ChatService, model: String, sink: ([Message]) -> Void) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages)
            try await service.completionStream(request: req) { message in
                apply(delta: message)
                await MainActor.run { sink(messages) }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: VisionService, model: String) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            let message = try await service.completion(request: req)
            return append(message: message)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: VisionService, model: String, sink: ([Message]) -> Void) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            try await service.completionStream(request: req) { message in
                apply(delta: message)
                await MainActor.run { sink(messages) }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func sink(callback: ([Message]) -> Void) async -> Self {
        await MainActor.run { callback(messages) }
        return self
    }
    
    @discardableResult
    public func sinkError(callback: (Error?) -> Void) async -> Self {
        await MainActor.run { callback(error) }
        return self
    }

    // MARK: Private
    
    private func apply(delta message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = messages[index].apply(message)
        } else {
            messages.append(message)
        }
    }
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("MessageManager Error: \(error, privacy: .public)")
            self.error = error
        }
    }
}
