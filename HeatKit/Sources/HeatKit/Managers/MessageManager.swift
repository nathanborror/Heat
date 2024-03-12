import Foundation
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    public typealias MessageCallback = (Message) -> Void
    
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
    public func generateStream(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback, processing: (() -> Void)? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            
            var shouldContinue = true
            
            // What could go wrong?
            while shouldContinue {
                var message: Message? = nil
                
                // Prepare chat request for service
                let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
                
                // Generate completion stream
                try await service.completionStream(request: req) { delta in
                    let messageDelta = apply(delta: delta)
                    message = messageDelta
                    await MainActor.run { callback(messageDelta) }
                }
                
                // Prepare possible tool responses
                await MainActor.run { processing?() }
                let toolResponses = try await prepareToolResponses(message: message)
                if toolResponses.isEmpty {
                    shouldContinue = false
                } else {
                    for response in toolResponses {
                        await self.append(message: response)
                        await MainActor.run { callback(response) }
                    }
                }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Tools
    
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
    
    private func prepareToolResponses(message: Message?) async throws -> [Message] {
        var messages = [Message]()
        guard let toolCalls = message?.toolCalls else { return [] }
        
        let summarizationService = try Store.shared.preferredSummarizationService()
        let summarizationModel = try Store.shared.preferredSummarizationModel()
        
        for toolCall in toolCalls {
            switch toolCall.function.name {
            
            // Web Search
            case Tool.generateWebSearch.function.name:
                do {
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
                        name: toolCall.function.name,
                        metadata: ["label": "Searched the web for '\(obj.query)'"]
                    )
                    messages.append(toolResponse)
                } catch {
                    let toolFailed = Message(role: .tool, content: "Tool Failed: \(error.localizedDescription)", toolCallID: toolCall.id, name: toolCall.function.name)
                    messages.append(toolFailed)
                }
                
            // Web Browser
            case Tool.generateWebBrowse.function.name:
                do {
                    let obj = try Tool.GenerateWebBrowse.decode(toolCall.function.arguments)
                    var context: [String] = []
                    for url in obj.urls {
                        let summary = try await BrowserManager().generateSummary(service: summarizationService, model: summarizationModel, url: url)
                        context.append("""
                            [\(url)]
                            
                            \(summary ?? "")
                            """)
                    }
                    let label = obj.urls.count == 1 ? "Read \(URL(string: obj.urls[0])?.host() ?? "")" : "Read \(obj.urls.count) webpages"
                    let toolResponse = Message(
                        role: .tool,
                        content: context.joined(separator: "\n\n"),
                        toolCallID: toolCall.id,
                        name: toolCall.function.name,
                        metadata: ["label": label]
                    )
                    messages.append(toolResponse)
                } catch {
                    let toolFailed = Message(role: .tool, content: "Tool Failed: \(error.localizedDescription)", toolCallID: toolCall.id, name: toolCall.function.name)
                    messages.append(toolFailed)
                }
                
            // Image prompts
            case Tool.generateImages.function.name:
                let obj = try Tool.GenerateImages.decode(toolCall.function.arguments)
                let toolResponse = Message(
                    role: .tool,
                    content: obj.prompts.joined(separator: "\n\n"),
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": obj.prompts.count == 1 ? "Generating an image" : "Generating \(obj.prompts.count) images"]
                )
                messages.append(toolResponse)
                
            default:
                break
            }
        }
        return messages
    }
}
