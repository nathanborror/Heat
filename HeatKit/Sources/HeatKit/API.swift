import Foundation
import GenKit

@MainActor @Observable
public final class API {
    public static let shared = API()
    
    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    public func generate(conversationID: String, prompt: String, context: [String: String] = [:], toolChoice: Tool? = nil, agentID: String? = nil) throws -> Task<(), Error> {
        guard !prompt.isEmpty else { return Task {()} }
        
        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        // Service and model
        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()
        
        return Task {
            let conversation = try conversationsProvider.get(conversationID)
            
            // Augment context
            var context = context
            context["DATETIME"] = Date.now.formatted()
            
            // New user message
            let userMessage = Message(role: .user, content: PromptTemplate(prompt, with: context))
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Fetch messages
            let messages = try messagesProvider.get(parentID: conversationID)
            
            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(system: PromptTemplate(conversation.instructions, with: context))
            req.with(history: messages)
            req.with(tools: Toolbox.get(names: conversation.toolIDs))
            req.with(context: context)
            
            // Generate response stream
            let stream = ChatSession.shared.stream(req)
            for try await message in stream {
                try Task.checkCancellation()
                
                // Indicate which agent was used
                var message = message
                if let agentID {
                    message.metadata.agentID = agentID
                }
                
                try await messagesProvider.upsert(message: message, parentID: conversation.id)
                try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
            }
            
            // Save messages
            try await messagesProvider.flush()
            
            // Generate suggestions and title in parallel
            Task {
                async let suggestions = generateSuggestions(conversationID: conversationID)
                async let title = generateTitle(conversationID: conversationID)
                try await (_, _) = (suggestions, title)
            }
        }
    }
    
    /// Generate a response using images as inputs alongside text. This will eventually be combined with generate(chat: ...) above.
    public func generate(conversationID: String, prompt: String, images: [Data], context: [String: String] = [:]) throws -> Task<(), Error> {
        guard !prompt.isEmpty else { return Task {()} }
        
        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        // Service and model
        let service = try preferencesProvider.preferredVisionService()
        let model = try preferencesProvider.preferredVisionModel()
        
        return Task {
            let conversation = try conversationsProvider.get(conversationID)
            
            // Augment context
            var context = context
            context["DATETIME"] = Date.now.formatted()
            
            // New user message
            let userMessage = Message(
                role: .user,
                content: PromptTemplate(prompt, with: context),
                attachments: images.map {
                    .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
                })
            try await messagesProvider.upsert(message: userMessage, parentID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Fetch messages
            let messages = try messagesProvider.get(parentID: conversationID)
            
            // Initial request
            var req = VisionSessionRequest(service: service, model: model)
            req.with(system: PromptTemplate(conversation.instructions, with: context))
            req.with(history: messages)
            req.with(context: context)
            
            // Generate response stream
            let stream = VisionSession.shared.stream(req)
            for try await message in stream {
                try Task.checkCancellation()
                try await messagesProvider.upsert(message: message, parentID: conversation.id)
                try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
            }
            
            // Save messages
            try await messagesProvider.flush()
            
            // Generate suggestions and title in parallel
            Task {
                async let suggestions = generateSuggestions(conversationID: conversationID)
                async let title = generateTitle(conversationID: conversationID)
                try await (_, _) = (suggestions, title)
            }
        }
    }
    
    /// Generate an image from a given prompt. This is an explicit way to generate an image, most happen through tool use.
    public func generate(conversationID: String, image prompt: String) throws -> Task<(), Error> {
        guard !prompt.isEmpty else { return Task {()} }
        
        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        // Service and model
        let service = try preferencesProvider.preferredImageService()
        let model = try preferencesProvider.preferredImageModel()
        
        return Task {
            let conversation = try conversationsProvider.get(conversationID)
            
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
            try await messagesProvider.flush()
        }
    }
    
    // MARK: - Private
    
    /// Generate a title for the conversation.
    private func generateTitle(conversationID: String) async throws -> Bool {
        
        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        let conversation = try conversationsProvider.get(conversationID)
        let messages = try messagesProvider.get(parentID: conversationID)
        
        guard conversation.title == nil else {
            return false
        }
        
        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()
        
        let history = messages
            .map { "\($0.role.rawValue): \($0.content ?? "Empty")" }
            .joined(separator: "\n\n")
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: PromptTemplate(TitleInstructions, with: ["HISTORY": history]))
        
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
    private func generateSuggestions(conversationID: String) async throws -> Bool {
        
        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        let conversation = try conversationsProvider.get(conversationID)
        let messages = try messagesProvider.get(parentID: conversationID)
        
        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()
        
        let history = messages
            .map { "\($0.role.rawValue): \($0.content ?? "Empty")" }
            .joined(separator: "\n\n")
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: PromptTemplate(SuggestionsInstructions, with: ["HISTORY": history]))
        
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
        }
        
        // Set conversation state
        try await conversationsProvider.upsert(state: .none, conversationID: conversation.id)
        
        // Success
        return true
    }
    
    /// Determine which tool is being called, execute the tool request if needed and return a tool call response before another turn of the conversation happens.
    @Sendable
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: false)
            case .generateMemory:
                let messages = await MemoryTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .searchCalendar:
                let messages = await CalendarSearchTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .searchWeb:
                let messages = await WebSearchTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .browseWeb:
                let messages = await WebBrowseTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .generateSuggestions, .generateTitle:
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
}
