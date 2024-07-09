import Foundation
import SwiftData
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    public typealias ManagerCallback = @MainActor (MessageManager) -> Void
    public typealias MessageCallback = @MainActor (Message) -> Void
    public typealias ProcessingCallback = @MainActor () -> Void
    public typealias ImagesCallback = @MainActor (String, [Data]) -> Void
    
    public private(set) var messages: [Message] = []
    public private(set) var error: Error? = nil
    
    private var filteredMessages: [Message] {
        messages.filter { ![.error, .local].contains($0.kind) }
    }
    
    public init() {}
    
    @discardableResult
    public func manage(callback: ManagerCallback) async -> Self {
        await callback(self)
        return self
    }
    
    @discardableResult
    public func append(messages: [Message]) -> Self {
        self.messages += messages
        return self
    }
    
    @discardableResult
    public func append(message: Message?, context: [String: any StringProtocol]? = nil, callback: MessageCallback? = nil) async -> Self {
        guard var message else { return self }
        message.content = message.content?.apply(context: context ?? [:])
        messages.append(message)
        await callback?(message)
        return self
    }
    
    // MARK: Generators
    
    @discardableResult
    public func generate(service: ChatService, model: String, tools: Set<Tool> = [], toolChoice: Tool? = nil, stream: Bool = true, callback: MessageCallback, processing: ProcessingCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            
            let runID = String.id
            var message: Message? = nil
            
            // Prepare chat request for service, DO NOT include a tool choice on any subsequent runs, this will
            // likely cause an expensive infinite loop of tool calls.
            let req = ChatServiceRequest(
                model: model,
                messages: filteredMessages,
                tools: tools,
                toolChoice: toolChoice
            )
            
            // Generate completion
            if stream {
                try await service.completionStream(request: req) { update in
                    message = apply(message: update, runID: runID)
                    await callback(message!)
                }
            } else {
                message = try await service.completion(request: req)
                message?.runID = runID
                await append(message: message!)
                await callback(message!)
            }

// Prepare possible tool responses
//                let (toolResponses, shouldContinue) = try await prepareToolsResponse(message: message, runID: runID)
//                for response in toolResponses {
//                    let message = apply(message: response, runID: runID)
//                    await callback(message)
//                }
//            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: ToolService, model: String, tool: Tool, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ToolServiceRequest(model: model, messages: filteredMessages, tool: tool)
            let message = try await service.completion(request: req)
            await append(message: message)
            await callback?(message)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: VisionService, model: String, stream: Bool = true, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            if stream {
                try await service.completionStream(request: req) { update in
                    let message = apply(message: update)
                    await callback?(message)
                }
            } else {
                let message = try await service.completion(request: req)
                await append(message: message)
                await callback?(message)
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: ImageService, model: String, prompt: String? = nil, callback: ImagesCallback) async -> Self {
        do {
            try Task.checkCancellation()
            let prompt = prompt ?? ""
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let images = try await service.imagine(request: req)
            await callback(prompt, images)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generate(service: SpeechService, model: String, voice: String?, callback: MessageCallback) async -> Self {
        guard let voice else { return self }
        do {
            try Task.checkCancellation()
            guard let message = filteredMessages.last else { return self }
            guard let content = message.content, message.role == .assistant else { return self }
            
            let req = SpeechServiceRequest(voice: voice, model: model, input: content, responseFormat: .mp3)
            let data = try await service.speak(request: req)
            
            let resource = Resource.document("\(String.id).mp3")
            try data.write(to: resource.url!)
            
            let attachment = Message.Attachment.asset(.init(name: resource.name, kind: .audio, location: .filesystem))
            let newMessage = apply(attachment: attachment, message: message)
            await callback(newMessage)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // MARK: Appliers
    
    private func apply(message: Message, runID: String? = nil) -> Message {
        var message = message
        message.runID = runID
        
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            return message
        } else {
            messages.append(message)
            return message
        }
    }
    
    private func apply(attachment: Message.Attachment, message: Message) -> Message {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            var newMessage = messages[index]
            newMessage.attachments.append(attachment)
            newMessage.modified = .now
            messages[index] = newMessage
            return newMessage
        } else {
            var newMessage = message
            newMessage.attachments.append(attachment)
            messages.append(newMessage)
            return newMessage
        }
    }
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("MessageManagerError: \(error, privacy: .public)")
            self.error = error
        }
    }
}
