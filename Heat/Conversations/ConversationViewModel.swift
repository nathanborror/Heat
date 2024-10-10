import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "App")

@Observable @MainActor
final class ConversationViewModel {
    var conversationID: String? = nil
    var streamingTokens: String? = nil
    var error: Error? = nil
    
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private var generateTask: Task<(), Error>? = nil
    
    init(conversationID: String) {
        self.conversationID = conversationID
    }
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? conversationsProvider.get(conversationID)
    }
    
    /// Suggested replies the user can use to respond.
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    /// The instructions (system prompt) that's sent with every request.'
    var instructions: [Message] {
        guard let conversation else { return [] }
        let instructions = Message(role: .system, content: conversation.instructions)
        return [instructions]
    }
    
    /// The whole conversation history.
    var messages: [Message] {
        guard let conversationID else { return [] }
        let history = try? messagesProvider.get(parentID: conversationID)
        return history ?? []
    }
    
    /// The conversation history aggregated by Run which packages up all tool calls and responses into a Run.
    var runs: [Run] {
        guard conversationID != nil else { return [] }
        return prepareRuns()
    }
    
    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    func generate(chat prompt: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(system: Prompt.render(conversation.instructions, with: ["DATETIME": Date.now.formatted()]))
            req.with(history: messages)
            req.with(tools: Toolbox.get(names: conversation.toolIDs))
            req.with(context: context)
            
            // Generate response stream
            let stream = ChatSession.shared.stream(req)
            for try await message in stream {
                try Task.checkCancellation()
                try await messagesProvider.upsert(message: message, parentID: conversation.id)
                try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
                streamingTokens = message.content
                haptic(tap: .light)
            }
            streamingTokens = nil
            
            // Save messages
            try await messagesProvider.save()
            
            // Generate suggestions and title in parallel
            Task {
                async let suggestions = generateSuggestions()
                async let title = generateTitle()
                try await (_, _) = (suggestions, title)
            }
        }
    }
    
    /// Generate a response using images as inputs alongside text. This will eventually be combined with generate(chat: ...) above.
    func generate(chat prompt: String, images: [Data], context: [String] = []) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredVisionService()
        let model = try PreferencesProvider.shared.preferredVisionModel()
        
        generateTask = Task {
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt, attachments: images.map {
                .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
            })
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Initial request
            var req = VisionSessionRequest(service: service, model: model)
            req.with(system: Prompt.render(conversation.instructions, with: ["DATETIME": Date.now.formatted()]))
            req.with(history: messages)
            req.with(context: context)
            
            // Generate response stream
            let stream = VisionSession.shared.stream(req)
            for try await message in stream {
                try Task.checkCancellation()
                try await messagesProvider.upsert(message: message, parentID: conversation.id)
                try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
                streamingTokens = message.content
                haptic(tap: .light)
            }
            streamingTokens = nil
            
            // Save messages
            try await messagesProvider.save()
            
            // Generate suggestions and title in parallel
            Task {
                async let suggestions = generateSuggestions()
                async let title = generateTitle()
                try await (_, _) = (suggestions, title)
            }
        }
    }
    
    /// Generate an image from a given prompt. This is an explicit way to generate an image, most happen through tool use.
    func generate(image prompt: String) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredImageService()
        let model = try PreferencesProvider.shared.preferredImageModel()
        
        generateTask = Task {
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Generate image
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let data = try await service.imagine(req)
            
            // Save images as assistant response
            let attachments = data.map {
                Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: prompt))
            }
            let message = Message(role: .assistant, content: "A generated image using the prompt:\n\(prompt)", attachments: attachments)
            try await messagesProvider.upsert(message: message, parentID: conversation.id)
            try await conversationsProvider.upsert(state: .none, conversationID: conversation.id)
            try await messagesProvider.save()
            haptic(tap: .heavy)
            
            streamingTokens = message.content
            streamingTokens = nil
        }
    }
    
    /// Generate a title for the conversation.
    func generateTitle() async throws -> Bool {
        guard let conversation else { return false }
        guard conversation.title == nil else {
            return false
        }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        let history = messages
            .map { "\($0.role.rawValue): \($0.content ?? "Empty")" }
            .joined(separator: "\n\n")
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: Prompt.render(TitleInstructions, with: ["HISTORY": history]))
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()
            guard let content = message.content else { continue }
            
            let name = "title"
            let result = try ContentParser.shared.parse(input: content, tags: [name])
            let tag = result.first(tag: name)
            
            guard let title = tag?.content else { continue }
            try await conversationsProvider.upsert(title: title, conversationID: conversation.id)
        }
        
        // Success
        return true
    }
    
    /// Generate conversation suggestions related to what's being talked about.
    func generateSuggestions() async throws -> Bool {
        guard let conversation else { return false }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        let history = messages
            .map { "\($0.role.rawValue): \($0.content ?? "Empty")" }
            .joined(separator: "\n\n")
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: Prompt.render(SuggestionsInstructions, with: ["HISTORY": history]))
        
        // Indicate we are suggesting
        try await conversationsProvider.upsert(state: .suggesting, conversationID: conversation.id)
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()
            guard let content = message.content else { continue }
            
            let name = "suggested_replies"
            let result = try ContentParser.shared.parse(input: content, tags: [name])
            let tag = result.first(tag: name)
            
            guard let content = tag?.content else { continue }
            let suggestions = content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
            
            try await conversationsProvider.upsert(suggestions: suggestions, conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
            streamingTokens = message.content
            haptic(tap: .light)
        }
        streamingTokens = nil
        
        // Set conversation state
        try await conversationsProvider.upsert(state: .none, conversationID: conversation.id)
        
        // Success
        return true
    }
    
    /// Cancel any of the generate tasks above.
    func cancel() {
        generateTask?.cancel()
        streamingTokens = nil
        Task {
            guard let conversationID else { return }
            try await conversationsProvider.upsert(state: .none, conversationID: conversationID)
        }
    }
    
    // MARK: - Private
    
    /// Determine which tool is being called, execute the tool request if needed and return a tool call response before another turn of the conversation happens.
    @Sendable
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
                haptic(tap: .heavy)
                return .init(messages: messages, shouldContinue: false)
            case .generateMemory:
                let messages = await MemoryTool.handle(toolCall)
                haptic(tap: .heavy)
                return .init(messages: messages, shouldContinue: true)
            case .searchCalendar:
                let messages = await CalendarSearchTool.handle(toolCall)
                haptic(tap: .heavy)
                return .init(messages: messages, shouldContinue: true)
            case .searchWeb:
                let messages = await WebSearchTool.handle(toolCall)
                haptic(tap: .heavy)
                return .init(messages: messages, shouldContinue: true)
            case .browseWeb:
                let messages = await WebBrowseTool.handle(toolCall)
                haptic(tap: .heavy)
                return .init(messages: messages, shouldContinue: true)
            case .generateSuggestions, .generateTitle, .searchFiles:
                return .init(messages: [], shouldContinue: false)
            }
        } else {
            let toolResponse = Message(
                role: .tool,
                content: "Unknown tool.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": "Unknown tool"]
            )
            return .init(messages: [toolResponse], shouldContinue: false)
        }
    }
    
    /// Bundle messages into runs.
    private func prepareRuns() -> [Run] {
        var runs: [Run] = []
        var currentRun = Run()
        
        // Cluster message runs
        for message in messages {
            if currentRun.id == message.runID {
                currentRun.messages.append(message)
                currentRun.ended = message.modified
            } else {
                if !currentRun.messages.isEmpty {
                    runs.append(currentRun)
                }
                currentRun = Run(
                    id: message.runID ?? message.id,
                    messages: [message],
                    started: message.created,
                    ended: message.modified
                )
            }
        }
        
        // Append remaining run
        if !currentRun.messages.isEmpty {
            runs.append(currentRun)
        }
        
        return runs
    }
    
    /// Execute a haptic tap.
    private func haptic(tap style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
}

