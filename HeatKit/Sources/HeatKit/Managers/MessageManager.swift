import Foundation
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "MessageManager", category: "HeatKit")

public final class MessageManager {
    public typealias ManagerCallback = @MainActor (MessageManager) -> Void
    public typealias MessageCallback = @MainActor (Message) -> Void
    public typealias ProcessingCallback = @MainActor () -> Void
    public typealias ImagesCallback = @MainActor (String, [Data]) -> Void
    
    public private(set) var messages: [Message]
    public private(set) var error: Error?
    
    private var filteredMessages: [Message] {
        messages.filter { ![.error, .local].contains($0.kind) }
    }
    
    public init(messages: [Message] = []) {
        self.messages = messages
    }
    
    @discardableResult
    public func manage(callback: ManagerCallback) async -> Self {
        await callback(self)
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
    
    @discardableResult
    public func upsert(message: Message, callback: MessageCallback? = nil) async -> Self {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        await callback?(message)
        return self
    }
    
    // Chat
    
    @discardableResult
    public func generate(service: ChatService, model: String, tools: Set<Tool> = [], stream: Bool = true, callback: MessageCallback, processing: ProcessingCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            
            let runID = String.id
            var runShouldContinue = true
            
            while runShouldContinue {
                var message: Message? = nil
                
                // Prepare chat request for service
                let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
                
                // Generate completion
                if stream {
                    try await service.completionStream(request: req) { delta in
                        let messageDelta = apply(delta: delta)
                        message = messageDelta
                        await callback(messageDelta)
                    }
                } else {
                    message = try await service.completion(request: req)
                    await append(message: message!)
                    await callback(message!)
                }
                
                // Prepare possible tool responses
                await processing?()
                
                // Prepare possible tool responses
                let (toolResponses, shouldContinue) = try await prepareToolResponses(message: message, runID: runID)
                for response in toolResponses {
                    await self.upsert(message: response)
                    await callback(response)
                }
                runShouldContinue = shouldContinue
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
            await callback?(message)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Vision
    
    @discardableResult
    public func generate(service: VisionService, model: String, stream: Bool = true, callback: MessageCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            let req = VisionServiceRequest(model: model, messages: filteredMessages, maxTokens: 1000)
            if stream {
                try await service.completionStream(request: req) { message in
                    let message = apply(delta: message)
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
    
    // Images
    
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
    
    // Speech
    
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
            logger.error("MessageManagerError: \(error, privacy: .public)")
            self.error = error
        }
    }
    
    // MARK: Preparers
    
    private func prepareToolResponses(message: Message?, runID: String? = nil) async throws -> ([Message], Bool) {
        guard let toolCalls = message?.toolCalls else { return ([], false) }
        
        struct TaskResponse {
            var messages: [Message]
            var shouldContinue: Bool
        }
        
        // Parallelize tool calls.
        var responses: [TaskResponse] = []
        await withTaskGroup(of: TaskResponse.self) { group in
            for toolCall in toolCalls {
                group.addTask {
                    do {
                        let (messages, shouldContinue) = try await self.prepareToolResponse(toolCall: toolCall)
                        return .init(messages: messages, shouldContinue: shouldContinue)
                    } catch {
                        return .init(messages: [], shouldContinue: true)
                    }
                }
            }
            for await response in group {
                responses.append(response)
            }
        }
        
        // Flatten messages from task responses and annotate each message with a Run identifier.
        let messages = responses
            .flatMap { $0.messages }
            .map {
                var message = $0
                message.runID = runID
                return message
            }
        
        // If any task response suggests the Run should stop, stop it.
        let shouldContinue = !responses.contains(where: { $0.shouldContinue == false })
        
        return (messages, shouldContinue)
    }
    
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ([Message], Bool) {
        switch toolCall.function.name {
        
        // Web search
        case Tool.generateWebSearch.function.name:
            do {
                let obj = try Tool.GenerateWebSearch.decode(toolCall.function.arguments)
                let response = try await prepareSearchResults(obj.query)
                let toolResponse = Message(
                    role: .tool,
                    content: response,
                    toolCallID: toolCall.id,
                    name: toolCall.function.name,
                    metadata: ["label": "Searched the web for '\(obj.query)'"]
                )
                return ([toolResponse], true)
            } catch {
                let toolFailed = Message(
                    role: .tool,
                    content: "Tool Failed: \(error.localizedDescription)",
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )
                return ([toolFailed], true)
            }
            
        // Web browser
        case Tool.generateWebBrowse.function.name:
            do {
                let toolResponse = try await prepareWebBrowseResponse(toolCall: toolCall)
                return ([toolResponse], true)
            } catch {
                let toolFailed = Message(
                    role: .tool,
                    content: "Tool Failed: \(error.localizedDescription)",
                    toolCallID: toolCall.id,
                    name: toolCall.function.name
                )
                return ([toolFailed], true)
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
            return ([toolResponse], false)
        
        // Unknown tool
        default:
            let toolResponse = Message(
                kind: .local,
                role: .tool,
                content: toolCall.function.arguments,
                name: toolCall.function.name,
                metadata: ["label": "Unknown tool"]
            )
            return ([toolResponse], true)
        }
    }
    
    private func prepareSearchResults(_ query: String) async throws -> String? {
        let searchResponse = try await SearchManager.shared.search(query: query)
        let toolResponse = Tool.GenerateWebSearchResponse(
            instructions: """
                Do not perform another search unless the results below are unhelpful. Pick the three most relevant \
                results to browse the webpages using the `\(Tool.generateWebBrowse.function.name)` function. When you \
                have finished browsing the results prepare a response that compares and contrasts the information \
                you've gathered. Remember to use citations.
                """,
            results: searchResponse.results
        )
        let data = try encoder.encode(toolResponse)
        return String(data: data, encoding: .utf8)
    }
    
    private func prepareWebBrowseResponse(toolCall: ToolCall) async throws -> Message {
        let obj = try Tool.GenerateWebBrowse.decode(toolCall.function.arguments)
        let sources = try await prepareWebBrowseSummary(webpage: obj)
        
        let sourcesData = try JSONEncoder().encode(sources)
        let sourcesString = String(data: sourcesData, encoding: .utf8)
        
        let label = "Read \(URL(string: obj.url)?.host() ?? "")"
        let toolResponse = Message(
            role: .tool,
            content: sourcesString,
            toolCallID: toolCall.id,
            name: toolCall.function.name,
            metadata: ["label": label]
        )
        return toolResponse
    }
    
    private func prepareWebBrowseSummary(webpage: Tool.GenerateWebBrowse) async throws -> Tool.GenerateWebBrowse.Source {
        let summarizationService = try Store.shared.preferredSummarizationService()
        let summarizationModel = try Store.shared.preferredSummarizationModel()
        
        logger.debug("Browsing: \(webpage.url)")
        do {
            let summary = try await BrowserManager().generateSummary(service: summarizationService, model: summarizationModel, url: webpage.url)
            logger.debug("Summarized: \(webpage.url)")
            return .init(
                title: webpage.title,
                url: webpage.url,
                summary: summary,
                success: true
            )
        } catch {
            logger.error("Failed to generate summary")
            return .init(
                title: webpage.title,
                url: webpage.url,
                summary: nil,
                success: false
            )
        }
    }
    
    // MARK: Encoders
    
    private var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
}
