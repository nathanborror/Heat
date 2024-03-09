import Foundation
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    public typealias MessageCallback = (Message) -> Void
    public typealias MessageCompletionCallback = (Message) async throws -> ToolsResponse?
    
    public private(set) var messages: [Message]
    public private(set) var error: Error?
    public private(set) var hasToolResponses = false
    
    private var filteredMessages: [Message] {
        messages.filter { $0.kind != .error && $0.kind != .ignore }
    }
    
    public init(messages: [Message] = []) {
        self.messages = messages
    }
    
    @discardableResult
    public func manage(callback: (MessageManager) -> Void) async -> Self {
        await MainActor.run { callback(self) }
        return self
    }
    
    @discardableResult
    public func append(message: Message, callback: MessageCallback? = nil) async -> Self {
        messages.append(message)
        await MainActor.run { callback?(message) }
        return self
    }
    
    // Chat
    
    @discardableResult
    public func generate(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
            let message = try await service.completion(request: req)
            await append(message: message)
            await MainActor.run { callback?(message) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback? = nil, completion: MessageCompletionCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
            var message: Message? = nil
            try await service.completionStream(request: req) { delta in
                let messageDelta = apply(delta: delta)
                message = messageDelta
                await MainActor.run { callback?(messageDelta) }
            }
            
            // Return the final message and append any toolCall responses that are returned from the completion
            // callback. If there are any responses then we flag the manager to allow a new stream to be executed
            // to respond to the toolCall responses.
            if let message, let resp = try await completion?(message) {
                self.messages += resp.messages
                self.hasToolResponses = resp.shouldContinue
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateLoop(service: ChatService, model: String, tools: Set<Tool>, callback: MessageCallback) async -> Self {
        do {
            try Task.checkCancellation()
            
            var shouldContinue = true

            while shouldContinue {
                let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
                var message: Message? = nil
                try await service.completionStream(request: req) { delta in
                    let messageDelta = apply(delta: delta)
                    message = messageDelta
                    await MainActor.run { callback(messageDelta) }
                }
                
                if let message {
                    let toolMessages = try await prepareToolResponses(message)
                    if !toolMessages.isEmpty {
                        for message in toolMessages {
                            await self.append(message: message)
                            await MainActor.run { callback(message) }
                        }
                    } else {
                        shouldContinue = false
                    }
                } else {
                    shouldContinue = false
                }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStreamForToolResponses(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback? = nil, completion: MessageCompletionCallback? = nil) async -> Self {
        guard hasToolResponses else { return self }
        hasToolResponses = false
        
        // If there are no toolCall responses then this step is ignored. Explicitly making the choice not to provide
        // any tools to avoid a loop but this may change in the future.
        return await generateStream(service: service, model: model, tools: tools, callback: callback, completion: completion)
    }
    
    // Tools
    
    @discardableResult
    public func generateStream(service: ToolService, model: String, tool: Tool, callback: MessageCallback? = nil, completion: MessageCompletionCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ToolServiceRequest(model: model, messages: filteredMessages, tool: tool)
            var message: Message? = nil
            try await service.completionStream(request: req) { delta in
                let messageDelta = apply(delta: delta)
                message = messageDelta
                await MainActor.run { callback?(messageDelta) }
            }
            
            // Return the final message and append any toolCall responses that are returned from the completion
            // callback. If there are any responses then we flag the manager to allow a new stream to be executed
            // to respond to the toolCall responses.
            if let message, let resp = try await completion?(message) {
                self.messages += resp.messages
                self.hasToolResponses = resp.shouldContinue
            }
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
            await MainActor.run { callback?(message) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Vision
    
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
    
    // Images
    
    @discardableResult
    public func generate(service: ImageService, model: String, prompt: String? = nil, callback: (String, [Data]) -> Void) async -> Self {
        do {
            try Task.checkCancellation()
            let prompt = prompt ?? ""
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let images = try await service.imagine(request: req)
            await MainActor.run { callback(prompt, images) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Speech
    
    @discardableResult
    public func generate(service: SpeechService, model: String, voice: String?, callback: (Message) -> Void) async -> Self {
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
            await MainActor.run { callback(newMessage) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // MARK: Helpers
    
    public func remove(message: Message) {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        messages.remove(at: index)
    }
    
    // MARK: Private
    
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
            logger.error("MessageManager Error: \(error, privacy: .public)")
            self.error = error
        }
    }
    
    private func prepareToolResponses(_ message: Message) async throws -> [Message] {
        var messages = [Message]()
        guard let toolCalls = message.toolCalls else { return [] }
        
        for toolCall in toolCalls {
            switch toolCall.function.name {
            
            // Web Search
            case Tool.generateWebSearch.function.name:
                let obj = try Tool.GenerateWebSearch.decode(toolCall.function.arguments)
                let response = try await SearchManager.shared.search(query: obj.query)
                let toolResponse = Message(
                    role: .tool,
                    content: """
                        Use the following search results to choose the top three URLs to browse using your \
                        `browse_web` function. Do not perform another search.
                        
                        Search Results:
                        \(response.results.map { $0.description }.joined(separator: "\n\n"))
                        """,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )
                messages.append(toolResponse)
                
            // Web Browser
            case Tool.generateWebBrowse.function.name:
                let obj = try Tool.GenerateWebBrowse.decode(toolCall.function.arguments)
                var context: [String] = []
                for url in obj.urls {
                    let markdown = try await BrowserManager.shared.fetch(url: URL(string: url)!, urlMode: .omit, hideJSONLD: true, hideImages: true)
                    context.append(markdown)
                }
                let toolResponse = Message(
                    role: .tool,
                    content: context.joined(separator: "\n\n"),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )
                messages.append(toolResponse)
            
            // Image prompts
            case Tool.generateImages.function.name:
                let obj = try Tool.GenerateImages.decode(toolCall.function.arguments)
                let toolResponse = Message(
                    role: .tool,
                    content: obj.prompts.joined(separator: "\n\n"),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )
                messages.append(toolResponse)
                
            default:
                break
            }
        }
        return messages
    }
    
    public struct ToolsResponse {
        public var messages: [Message]
        public var shouldContinue: Bool
        
        public init(messages: [Message] = [], shouldContinue: Bool = false) {
            self.messages = messages
            self.shouldContinue = shouldContinue
        }
    }
}
