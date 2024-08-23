import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "Heat")

@Observable
@MainActor
final class ConversationViewModel {
    var conversationID: String? = nil
    var error: Error? = nil
    
    private var generateTask: Task<(), Error>? = nil
    
    var conversation: Conversation? {
        guard let conversationID else { return nil }
        return try? ConversationsProvider.shared.get(conversationID)
    }
    
    var suggestions: [String] {
        Array((conversation?.suggestions ?? []).prefix(3))
    }
    
    var messages: [Message] {
        conversation?.messages ?? []
    }
    
    func newConversation() async throws {
        guard let agentID = PreferencesProvider.shared.preferences.defaultAgentID else {
            return
        }
        let agent = try AgentsProvider.shared.get(agentID)
        let instructions = agent.instructions
        let tools = Toolbox.get(tools: agent.toolIDs)
        let conversation = try await ConversationsProvider.shared.create(instructions: instructions, tools: tools)
        conversationID = conversation.id
    }
    
    func generate(chat prompt: String, memories: [String] = [], toolChoice: Tool? = nil) throws {
        guard !prompt.isEmpty else { return }
        
        let provider = ConversationsProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
            guard var conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await provider.upsert(suggestions: [], conversationID: conversation.id)
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            
            // Update conversation
            conversation = try provider.get(conversation.id)
            
            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(messages: conversation.messages)
            req.with(tools: conversation.tools)
            req.with(memories: memories)
            
            // Generate response stream
            let stream = ChatSession.shared.stream(req)
            for try await message in stream {
                try await provider.upsert(message: message, conversationID: conversation.id)
                try await provider.upsert(state: .streaming, conversationID: conversation.id)
            }
            
            // Generate suggestions and title in parallel
            Task {
                async let suggestions = generateSuggestions()
                async let title = generateTitle()
                try await (_, _) = (suggestions, title)
            }
        }
    }
    
    func generate(chat prompt: String, images: [Data], memories: [String] = []) throws {
        guard !prompt.isEmpty else { return }
        
        let provider = ConversationsProvider.shared
        let service = try PreferencesProvider.shared.preferredVisionService()
        let model = try PreferencesProvider.shared.preferredVisionModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
            guard var conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt, attachments: images.map {
                .asset(.init(name: "image", data: $0, kind: .image, location: .none, noop: false))
            })
            try await provider.upsert(suggestions: [], conversationID: conversation.id)
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            
            // Update conversation
            conversation = try provider.get(conversation.id)
            
            // Initial request
            var req = VisionSessionRequest(service: service, model: model)
            req.with(messages: conversation.messages)
            req.with(memories: memories)
            
            // Generate response stream
            let stream = VisionSession.shared.stream(req)
            for try await message in stream {
                try await provider.upsert(message: message, conversationID: conversation.id)
                try await provider.upsert(state: .streaming, conversationID: conversation.id)
            }
            
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
        
        let provider = ConversationsProvider.shared
        let service = try PreferencesProvider.shared.preferredImageService()
        let model = try PreferencesProvider.shared.preferredImageModel()
        
        generateTask = Task {
            if conversationID == nil {
                try await newConversation()
            }
            guard let conversation else { return }
            
            // New user message
            let userMessage = Message(role: .user, content: prompt)
            try await provider.upsert(message: userMessage, conversationID: conversation.id)
            try await provider.upsert(state: .processing, conversationID: conversation.id)
            
            // Generate image
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let data = try await service.imagine(request: req)
            
            // Save images as assistant response
            let attachments = data.map {
                Message.Attachment.asset(.init(name: "image", data: $0, kind: .image, location: .none, description: prompt))
            }
            let message = Message(role: .assistant, content: "A generated image using the prompt:\n\(prompt)", attachments: attachments)
            try await provider.upsert(message: message, conversationID: conversation.id)
            try await provider.upsert(state: .none, conversationID: conversation.id)
        }
    }
    
    func generateTitle() async throws -> Bool {
        guard let conversation else {
            throw KitError.missingConversation
        }
        guard conversation.title == nil else {
            return false
        }
        
        let provider = ConversationsProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        // Prepare messages
        var messages = conversation.messages
        messages.append(.init(role: .user, content: titlePrompt()))
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(messages: messages)
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            guard let content = message.content else { return false }
            
            let regex = #/<title>(.*?)(?:</title>|</ti|</t|<\/|<|$)/#
            if let match = content.prefixMatch(of: regex) {
                let title = String(match.output.1)
                guard !title.isEmpty else { continue }
                try await provider.upsert(title: title, conversationID: conversation.id)
            }
        }
        
        // Success
        return true
    }
    
    func generateSuggestions() async throws -> Bool {
        guard let conversation else {
            throw KitError.missingConversation
        }
        
        let provider = ConversationsProvider.shared
        let service = try PreferencesProvider.shared.preferredChatService()
        let model = try PreferencesProvider.shared.preferredChatModel()
        
        // Prepare messages
        var messages = conversation.messages
        messages.append(.init(role: .user, content: suggestionsPrompt()))
        
        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(messages: messages)
        
        // Indicate we are suggesting
        try await provider.upsert(state: .suggesting, conversationID: conversation.id)
        
        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            guard let content = message.content else { return false }
            let suggestions = content
                .split(separator: "\n")
                .map { String($0) }
                .filter { !$0.hasPrefix("<") }
                .map { String($0.trimmingPrefix(#/^-( )?/#)) }
            try await provider.upsert(suggestions: suggestions, conversationID: conversation.id)
            try await provider.upsert(state: .streaming, conversationID: conversation.id)
        }
        
        // Set conversation state
        try await provider.upsert(state: .none, conversationID: conversation.id)
        
        // Success
        return true
    }
    
    func stop() {
        generateTask?.cancel()
        guard let conversationID else { return }
        Task { try await ConversationsProvider.shared.upsert(state: .none, conversationID: conversationID) }
    }
    
    // MARK: - Private
    
    private func prepareSuggestions(_ message: Message) -> [String] {
        guard let toolCalls = message.toolCalls else { return [] }
        guard let toolCall = toolCalls.first(where: { $0.function.name == Toolbox.generateSuggestions.name }) else { return [] }
        do {
            let args = try SuggestTool.Arguments(toolCall.function.arguments)
            return Array(args.prompts.prefix(3))
        } catch {
            self.error = KitError.failedSuggestions
        }
        return []
    }
    
    private func prepareTitle(_ message: Message) -> String? {
        guard let toolCalls = message.toolCalls else { return nil }
        guard let toolCall = toolCalls.first(where: { $0.function.name == Toolbox.generateTitle.name }) else { return nil }
        do {
            let args = try TitleTool.Arguments(toolCall.function.arguments)
            return args.title
        } catch {
            print(error)
        }
        return nil
    }
    
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: false)
            case .generateMemory:
                let messages = await MemoryTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .generateSuggestions:
                return .init(messages: [], shouldContinue: false)
            case .generateTitle:
                return .init(messages: [], shouldContinue: false)
            case .searchFiles:
                return .init(messages: [], shouldContinue: false)
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
                metadata: ["label": "Unknown tool"]
            )
            return .init(messages: [toolResponse], shouldContinue: false)
        }
    }
    
    private func hapticTap(style: HapticManager.FeedbackStyle) {
        HapticManager.shared.tap(style: style)
    }
}

