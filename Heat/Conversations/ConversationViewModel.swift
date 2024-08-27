import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
@MainActor
final class ConversationViewModel {
    var conversationID: String? = nil
    var streamingTokens: String? = nil
    var error: Error? = nil
    
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private var generateTask: Task<(), Error>? = nil
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? conversationsProvider.get(conversationID)
    }
    
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    var instructions: [Message] {
        guard let conversation else { return [] }
        let instructions = Message(role: .system, content: conversation.instructions)
        return [instructions]
    }
    
    var messages: [Message] {
        guard let conversationID else { return [] }
        let history = try? messagesProvider.get(parentID: conversationID)
        return history ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesProvider.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentsProvider.shared.get(agentID)
        let instructions = agent.instructions
        let conversation = try await ConversationsProvider.shared.create(instructions: instructions, toolIDs: agent.toolIDs)
        conversationID = conversation.id
    }
    
    func generate(chat prompt: String, context: [String] = [], toolChoice: Tool? = nil) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(system: conversation.instructions)
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
    
    func generate(chat prompt: String, images: [Data], context: [String] = []) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredVisionService()
        let model = try PreferencesProvider.shared.preferredVisionModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
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
            req.with(system: conversation.instructions)
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
    
    func generate(image prompt: String) throws {
        guard !prompt.isEmpty else { return }
        
        let service = try PreferencesProvider.shared.preferredImageService()
        let model = try PreferencesProvider.shared.preferredImageModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Generate image
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let data = try await service.imagine(request: req)
            
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
    
    func generateTitle() async throws -> Bool {
        guard let conversation else {
            throw KitError.missingConversation
        }
        guard conversation.title == nil else {
            return false
        }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: titlePrompt(history: messages))
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()
            guard let content = message.content else { continue }
            
            let name = "title"
            let result = try Parser.shared.parse(input: content, tags: [name])
            let tag = result.get(tag: name)
            
            guard let title = tag?.content, !title.isEmpty else { continue }
            try await conversationsProvider.upsert(title: title, conversationID: conversation.id)
        }
        
        // Success
        return true
    }
    
    func generateSuggestions() async throws -> Bool {
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: suggestionsPrompt(history: messages))
        
        // Indicate we are suggesting
        try await conversationsProvider.upsert(state: .suggesting, conversationID: conversation.id)
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()
            guard let content = message.content else { continue }
            
            let name = "suggested_replies"
            let result = try Parser.shared.parse(input: content, tags: [name])
            let tag = result.get(tag: name)
            
            guard let content = tag?.content else { continue }
            let suggestions = content.split(separator: .newlineSequence).map { String($0) }
            
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
    
    /// Execute a haptic tap.
    private func haptic(tap style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
}

