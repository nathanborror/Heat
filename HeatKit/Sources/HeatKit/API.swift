import Foundation
import SharedKit
import GenKit

@MainActor @Observable
public final class API {
    public static let shared = API()
    
    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    public func generate(conversationID: String, prompt: String, context: [String: Value] = [:], images: [Data] = [], toolChoice: Tool? = nil, agentID: String? = nil) throws -> Task<(), Error> {
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
            context["DATETIME"] = .string(Date.now.formatted())

            // New user message
            let imageContent = images.map { Message.Content.image(data: $0, format: .jpeg) }
            let textContent = Message.Content.text(PromptTemplate(prompt, with: context))

            let userMessage = Message(role: .user, contents: [textContent] + imageContent)
            try await messagesProvider.upsert(message: userMessage, referenceID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Fetch messages
            let messages = try messagesProvider.get(referenceID: conversationID)

            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(system: PromptTemplate(conversation.instructions, with: context))
            req.with(history: messages)
            req.with(tools: Toolbox.get(names: conversation.toolIDs))
            req.with(context: context)
            
            // Generate response stream
            let stream = ChatSession.shared.stream(req, runLoopLimit: 20)
            for try await message in stream {
                try Task.checkCancellation()

                // Indicate which agent was used
                var message = message
                if let agentID {
                    message.metadata["agentID"] = .string(agentID)
                }

                try await messagesProvider.upsert(message: message, referenceID: conversation.id)
                try await conversationsProvider.upsert(state: .streaming, conversationID: conversation.id)
            }

            // Save messages
            try await messagesProvider.flush()

            // Generate suggestions, title and memories
            try await generateSuggestions(conversationID: conversationID)
            try await generateTitle(conversationID: conversationID)
            try await generateMemories(conversationID: conversationID)
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
            try await messagesProvider.upsert(message: userMessage, referenceID: conversation.id)
            try await conversationsProvider.upsert(suggestions: [], conversationID: conversation.id)
            try await conversationsProvider.upsert(state: .processing, conversationID: conversation.id)
            
            // Generate image
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let data = try await service.imagine(req)
            
            // Save images as assistant response
            let contents: [Message.Content] = data.map { .image(data: $0, format: .jpeg) }
            let message = Message(
                role: .assistant,
                contents: contents + [
                    .text("A generated image using the prompt:\n\(prompt)")
                ]
            )
            try await messagesProvider.upsert(message: message, referenceID: conversation.id)
            try await conversationsProvider.upsert(state: .none, conversationID: conversation.id)
            try await messagesProvider.flush()
        }
    }
    
    // MARK: - Private

    /// Generate a title for the conversation.
    private func generateTitle(conversationID: String) async throws {

        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        let conversation = try conversationsProvider.get(conversationID)
        let messages = try messagesProvider.get(referenceID: conversationID)

        guard conversation.title == nil else {
            return
        }
        
        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()

        let history = plainTextHistory(messages)
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(history: [.init(role: .user, content: PromptTemplate(TitleInstructions, with: ["HISTORY": .string(history)]))])

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
    }
    
    /// Generate conversation suggestions related to what's being talked about.
    private func generateSuggestions(conversationID: String) async throws {

        // Providers
        let conversationsProvider = ConversationsProvider.shared
        let messagesProvider = MessagesProvider.shared
        let preferencesProvider = PreferencesProvider.shared
        
        let conversation = try conversationsProvider.get(conversationID)
        let messages = try messagesProvider.get(referenceID: conversationID)

        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()
        
        let history = plainTextHistory(messages)

        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(history: [.init(role: .user, content: PromptTemplate(SuggestionsInstructions, with: ["HISTORY": .string(history)]))])

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
    }

    /// Generates memories to store based on the last user message in the conversation.
    private func generateMemories(conversationID: String) async throws {

        // Providers
        let messagesProvider = MessagesProvider.shared
        let memoryProvider = MemoryProvider.shared
        let preferencesProvider = PreferencesProvider.shared

        let service = try preferencesProvider.preferredChatService()
        let model = try preferencesProvider.preferredChatModel()

        // Gather context
        let messages = try messagesProvider.get(referenceID: conversationID)
        let memories = try await memoryProvider.get()
        let existingMemories = memories.map { $0.content }.joined(separator: "\n")
        let lastUserMessage = messages.last(where: { $0.role == .user })

        // Prepare request
        let req = ChatServiceRequest(model: model, messages: [
            .init(
                role: .user,
                content: PromptTemplate(MemoryInstructions, with: [
                    "CONTENT": .string(lastUserMessage?.content ?? ""),
                    "MEMORIES": .string(existingMemories)
                ])
            )
        ])

        // Make request
        let resp = try await service.completion(req)
        guard let content = resp.content else { return }

        // Parse response content
        let name = "memories"
        let result = try ContentParser.shared.parse(input: content, tags: [name])
        let tag = result.first(tag: name)

        guard let memories = tag?.content else { return }
        for memory in memories.split(separator: "\n") {
            try await memoryProvider.upsert(.init(content: String(memory)))
        }
    }

    /// Determine which tool is being called, execute the tool request if needed and return a tool call response before another turn of the conversation happens.
    @Sendable
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
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
            }
        } else {
            let toolResponse = Message(
                role: .tool,
                content: "Unknown tool.",
                toolCallID: toolCall.id,
                name: toolCall.function.name,
                metadata: ["label": .string("Unknown tool")]
            )
            return .init(messages: [toolResponse], shouldContinue: false)
        }
    }

    private func plainTextHistory(_ messages: [Message]) -> String {
        var out = ""
        for message in messages {
            out += """
                \(message.role.rawValue):
                \(message.content ?? "")
                
                """
        }
        return out
    }
}
