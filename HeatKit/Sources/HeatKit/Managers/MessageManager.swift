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
    public func append(message: Message, context: [String: any StringProtocol]? = nil, callback: MessageCallback? = nil) async -> Self {
        var message = message
        message.content = message.content?.apply(context: context ?? [:])
        messages.append(message)
        await callback?(message)
        return self
    }
    
    // Chat
    
    @discardableResult
    public func generate(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback? = nil, processing: ProcessingCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            var shouldContinue = true
            
            while shouldContinue {
                
                // Prepare chat request for service
                let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
                
                // Generate completion
                let message = try await service.completion(request: req)
                await append(message: message)
                await callback?(message)
                
                // Prepare possible tool responses
                await processing?()
                
                // Prepare possible tool responses
                let toolResponses = try await prepareToolResponses(message: message)
                if toolResponses.isEmpty {
                    shouldContinue = false
                } else {
                    for response in toolResponses {
                        await self.append(message: response)
                        await callback?(response)
                    }
                }
                
                // Halt if the last message is from the assistant
                if filteredMessages.last?.role == .assistant {
                    shouldContinue = false
                }
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    @discardableResult
    public func generateStream(service: ChatService, model: String, tools: Set<Tool> = [], callback: MessageCallback, processing: ProcessingCallback? = nil) async -> Self {
        do {
            try Task.checkCancellation()
            var shouldContinue = true
            
            while shouldContinue {
                var message: Message? = nil
                
                // Prepare chat request for service
                let req = ChatServiceRequest(model: model, messages: filteredMessages, tools: tools)
                
                // Generate completion stream
                try await service.completionStream(request: req) { delta in
                    let messageDelta = apply(delta: delta)
                    message = messageDelta
                    await callback(messageDelta)
                }
                
                // Prepare possible tool responses
                await processing?()
                
                // Prepare possible tool responses
                let toolResponses = try await prepareToolResponses(message: message)
                if toolResponses.isEmpty {
                    shouldContinue = false
                } else {
                    for response in toolResponses {
                        await self.append(message: response)
                        await callback(response)
                    }
                }
                
                // Halt if the last message is from the assistant
                if filteredMessages.last?.role == .assistant {
                    shouldContinue = false
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
            await callback?(message)
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
            await callback?(message)
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
            logger.error("MessageManagerError: \(error, privacy: .public)")
            self.error = error
        }
    }
    
    private func prepareToolResponses(message: Message?) async throws -> [Message] {
        var messages = [Message]()
        guard let toolCalls = message?.toolCalls else { return [] }
        
        for toolCall in toolCalls {
            switch toolCall.function.name {
            
            // Web Search
            case Tool.generateWebSearch.function.name:
                do {
                    let obj = try Tool.GenerateWebSearch.decode(toolCall.function.arguments)
                    let response = try await SearchManager.shared.search(query: obj.query)
                    
                    let resultsData = try JSONEncoder().encode(response.results)
                    let resultsString = String(data: resultsData, encoding: .utf8) ?? "[]"
                    
                    let toolResponse = Message(
                        role: .tool,
                        content: """
                            Do not perform another search unless the results below are unhelpful. Pick the three most \
                            relevant search results to browse using the `\(Tool.generateWebBrowse.function.name)` \
                            function. The `\(Tool.generateWebBrowse.function.name)` function can take multiple websites \
                            so try to only call it once. When you have browsed the results prepare a response that \
                            compares and contrasts the information you've gathered. Remember to use citations.
                            
                            Search Results:
                            
                            \(resultsString)
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
                    let toolResponse = try await prepareWebBrowseResponse(toolCall: toolCall)
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
    
    private func prepareWebBrowseResponse(toolCall: ToolCall) async throws -> Message {
        let obj = try Tool.GenerateWebBrowse.decode(toolCall.function.arguments)
        let sources = try await prepareWebBrowseSummaries(webpages: obj.webpages)
        
        let sourcesData = try JSONEncoder().encode(sources)
        let sourcesString = String(data: sourcesData, encoding: .utf8)
        
        let label = obj.webpages.count == 1 ? "Read \(URL(string: obj.webpages[0].url)?.host() ?? "")" : "Read \(obj.webpages.count) webpages"
        let toolResponse = Message(
            role: .tool,
            content: sourcesString,
            toolCallID: toolCall.id,
            name: toolCall.function.name,
            metadata: ["label": label]
        )
        return toolResponse
    }
    
    private func prepareWebBrowseSummaries(webpages: [Tool.GenerateWebBrowse.Webpage]) async throws -> [Tool.GenerateWebBrowse.Source] {
        let summarizationService = try Store.shared.preferredSummarizationService()
        let summarizationModel = try Store.shared.preferredSummarizationModel()
        
        var sources: [Tool.GenerateWebBrowse.Source] = []
        
        await withTaskGroup(of: Tool.GenerateWebBrowse.Source.self) { group in
            for webpage in webpages {
                group.addTask {
                    logger.debug("Browsing: \(webpage.url)")
                    do {
                        let summary = try await BrowserManager().generateSummary(service: summarizationService, model: summarizationModel, url: webpage.url)
                        logger.debug("Summarized: \(webpage.url)")
                        return .init(title: webpage.title ?? "No Title", url: webpage.url, summary: summary ?? "")
                    } catch {
                        logger.error("Failed to generate summary")
                        return .init(title: webpage.title ?? "No Title", url: webpage.url, summary: "Failed to summarize.")
                    }
                }
            }
            for await source in group {
                sources.append(source)
            }
        }
        return sources
    }
}
