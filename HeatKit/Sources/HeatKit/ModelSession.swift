import Foundation
import OSLog
import SharedKit
import GenKit

public struct ModelRequest {
    public let service: ChatService
    public let model: String
    
    public private(set) var messages: [Message] = []
    public private(set) var tools: Set<Tool> = []
    public private(set) var tool: Tool? = nil
    public private(set) var memories: [String] = []
    
    public init(service: ChatService, model: String) {
        self.service = service
        self.model = model
    }
    
    public mutating func with(messages: [Message]) {
        self.messages = messages
    }
    
    public mutating func with(tools: Set<Tool>) {
        self.tools = tools
    }
    
    public mutating func with(tool: Tool?) {
        if let tool {
            self.tool = tool
            self.tools.insert(tool)
        } else {
            self.tool = nil
        }
    }
    
    public mutating func with(memories: [String]) {
        self.memories = memories
    }
}

public struct ModelResponse {
    public let messages: [Message]
    
    // TODO: -
    // public func extract(tool: Tool) throws -> Tool.Arguments {}
    
    public func extractTool<T: Codable>(name: String, type: T.Type) throws -> T {
        guard let message = messages.last else {
            throw ModelSessionError.missingMessage
        }
        guard let toolCalls = message.toolCalls else {
            throw ModelSessionError.missingToolCalls
        }
        guard let toolCall = toolCalls.first(where: { $0.function.name == name }) else {
            throw ModelSessionError.missingToolCall
        }
        guard let data = toolCall.function.arguments.data(using: .utf8) else {
            throw ModelSessionError.unknown
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

public class ModelSession {
    public static let shared = ModelSession()
    
    public func chatCompletionStream(_ request: ModelRequest) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let runID = String.id
                
                var messages = request.messages
                var runLoopCount = 0
                var runShouldContinue = true
                
                while runShouldContinue {
                    
                    // Prepare chat request for service, DO NOT include a tool choice on any subsequent runs, this will
                    // likely cause an expensive infinite loop of tool calls.
                    let req = ChatServiceRequest(
                        model: request.model,
                        messages: messages,
                        tools: request.tools,
                        toolChoice: (runLoopCount > 0) ? nil : request.tool
                    )
                    
                    // Generate completion
                    try await request.service.completionStream(request: req) { update in
                        var message = update
                        message.runID = runID
                        
                        messages = apply(message: message, messages: messages)
                        continuation.yield(update)
                    }
                    
                    let lastMessage = messages.last!
                    
                    // Prepare possible tool responses
                    let (toolMessages, shouldContinue) = try await prepareToolsResponse(message: lastMessage, runID: runID)
                    for message in toolMessages {
                        messages = apply(message: message, messages: messages)
                        continuation.yield(message)
                    }
                    runShouldContinue = shouldContinue
                    runLoopCount += 1
                }
                
                continuation.finish()
            }
        }
    }
    
    public func chatCompletion(_ request: ModelRequest) async throws -> ModelResponse {
        let req = ChatServiceRequest(model: request.model, messages: request.messages, tools: request.tools, toolChoice: request.tool)
        let message = try await request.service.completion(request: req)
        return .init(messages: [message])
    }
    
    // MARK: Preparers
    
    private func prepareToolsResponse(message: Message?, runID: String? = nil) async throws -> ([Message], Bool) {
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
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                return (await ImageGeneratorTool.handle(toolCall), false)
            case .generateMemory:
                return (await MemoryTool.handle(toolCall), true)
            case .generateSuggestions:
                return ([], true)
            case .generateTitle:
                return ([], true)
            case .searchFiles:
                return (await FileSearchTool.handle(toolCall), true)
            case .searchCalendar:
                return (await CalendarSearchTool.handle(toolCall), true)
            case .searchWeb:
                return (await WebSearchTool.handle(toolCall), true)
            case .browseWeb:
                return (await WebBrowseTool.handle(toolCall), true)
            }
        } else {
            let toolResponse = Message(
                role: .tool,
                content: "Unknown tool.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Unknown tool"]
            )
            return ([toolResponse], true)
        }
    }
    
    // MARK: Appliers
    
    private func apply(message: Message, messages: [Message]) -> [Message] {
        var messages = messages
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
            return messages
        } else {
            messages.append(message)
            return messages
        }
    }
}

enum ModelSessionError: Error {
    case missingMessage
    case missingToolCalls
    case missingToolCall
    case unknown
}

/* Sketchpad

var req = ModelRequest(service, model)
req.with(messages: messages)
req.with(tools: tools)
req.with(memory: memory)

// Example streaming request
let stream = ModelSession.shared.chatCompletionStream(req)
for try await message in stream { message in
    // Handle message
}

// Update request messages with new history
req.replace(messages: resp.messages)

// Example non-streaming request
let resp = await ModelSession.shared.chatCompletion(req)

*/
