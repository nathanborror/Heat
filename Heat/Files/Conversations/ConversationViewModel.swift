import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationViewModel", category: "App")

@Observable @MainActor
final class ConversationViewModel {
    var file: File
    var conversation: Conversation

    private let state = AppState.shared
    private var generateTask: Task<(), Swift.Error>? = nil

    enum Error: Swift.Error, CustomStringConvertible {
        case generationError(String)
        case unexpectedError(String)
        case notFound(String)

        public var description: String {
            switch self {
            case .generationError(let detail):
                return "Generation error: \(detail)"
            case .unexpectedError(let detail):
                return "Unexpected error: \(detail)"
            case .notFound(let detail):
                return "Not Found error: \(detail)"
            }
        }
    }

    init(conversation: Conversation, file: File) {
        self.conversation = conversation
        self.file = file
    }

    /// Suggested replies the user can use to respond.
    var suggestions: [String] {
        Array((conversation.suggestions).prefix(3))
    }

    /// The instructions (system prompt) that's sent with every request.'
    var instructions: [Message] {
        let instructions = Message(role: .system, content: conversation.instructions)
        return [instructions]
    }

    /// The whole conversation history.
    var messages: [Message] {
        conversation.messages
    }

    /// The conversation history aggregated by Run which packages up all tool calls and responses into a Run.
    var runs: [Run] {
        prepareRuns()
    }

    var title: String {
        file.name ?? "Heat"
    }

    var subtitle: String {
        guard let (_, model) = try? API.shared.preferredChatService() else { return "Unknown model" }
        return model.name ?? model.id
    }

    // MARK: - Generators

    /// Generate a response using text as the only input. Add context—often memories—to augment the system prompt. Optionally force a tool call.
    func generate(chat prompt: String, images: [URL] = [], context: [String: Value] = [:], toolChoice: Tool? = nil) async throws {
        do {
            let (service, model) = try API.shared.preferredChatService()

            var context = context
            context["DATETIME"] = .string(Date.now.formatted())

            // New user message
            let imageContent = images.map { Message.Content.image(.init(url: $0, format: .jpeg)) }
            let textContent = Message.Content.text(PromptTemplate(prompt, with: context))

            let userMessage = Message(role: .user, contents: [textContent] + imageContent)
            conversation.messages.append(userMessage)
            conversation.suggestions = []
            conversation.state = .processing

            // Initial request
            var req = ChatSessionRequest(service: service, model: model, toolCallback: prepareToolResponse)
            req.with(system: PromptTemplate(conversation.instructions, with: context))
            req.with(history: conversation.messages)
            req.with(tools: Toolbox.get(names: conversation.toolIDs))
            req.with(context: context)

            // Generate response stream
            let stream = ChatSession.shared.stream(req)
            for try await message in stream {
                try Task.checkCancellation()

                if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
                    conversation.messages[index] = message
                } else {
                    conversation.messages.append(message)
                }
                conversation.state = .streaming
                file.modified = .now
            }

            // Reset conversation state
            conversation.state = .none

            // Generate suggestions
            try await generateSuggestions()

            // Generate title
            try await generateTitle()

            // Cache conversation
            try await API.shared.fileUpdate(file.id, object: conversation)
            try await API.shared.fileUpdate(file)
        } catch {
            throw Error.generationError("\(error)")
        }
    }

    func generateSuggestions() async throws {
        let (service, model) = try API.shared.preferredChatService()

        // Flattened message history
        let messages = conversation.messages
        let history = preparePlainTextHistory(messages)
        let content = PromptTemplate(SuggestionsInstructions, with: ["HISTORY": .string(history)])

        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(history: [.init(role: .user, content: content)])

        // Indicate we are suggesting
        conversation.state = .suggesting

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

            conversation.suggestions = suggestions
            conversation.state = .streaming
            file.modified = .now
        }

        // Set conversation state
        conversation.state = .none
    }

    func generateTitle() async throws {
        guard file.name == nil else { return }

        let (service, model) = try API.shared.preferredChatService()

        // Flatted message history
        let messages = conversation.messages
        let history = preparePlainTextHistory(messages)
        let content = PromptTemplate(TitleInstructions, with: ["HISTORY": .string(history)])

        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(history: [.init(role: .user, content: content)])

        // Generate suggestions stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()
            guard let content = message.content else { continue }

            let name = "title"
            let result = try ContentParser.shared.parse(input: content, tags: [name])
            let tag = result.first(tag: name)
            let tagIsEmpty = tag?.content?.isEmpty ?? true

            file.name = tagIsEmpty ? nil : tag?.content
            file.modified = .now
        }
    }

    func cancel() {
        generateTask?.cancel()
    }

    // MARK: - Private

    @Sendable // Determine tool to execute and return response before next turn of the conversation
    private func prepareToolResponse(toolCall: ToolCall) async throws -> ToolCallResponse {
        if let tool = Toolbox(name: toolCall.function.name) {
            switch tool {
            case .generateImages:
                let messages = await ImageGeneratorTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: false)
            case .searchWeb:
                let messages = await WebSearchTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .browseWeb:
                let messages = await WebBrowseTool.handle(toolCall)
                return .init(messages: messages, shouldContinue: true)
            case .searchCalendar:
                let messages = await CalendarSearchTool.handle(toolCall)
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
                let runID = (message.runID != nil && !message.runID!.isEmpty) ? message.runID! : message.id
                currentRun = Run(
                    id: runID,
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

    private func preparePlainTextHistory(_ messages: [Message]) -> String {
        var out = ""
        for message in messages {
            out += message.role.rawValue + ":\n"
            for content in message.contents ?? [] {
                guard case .text(let text) = content else { continue }
                out += text + "\n"
            }
            out += "\n"
        }
        return out
    }
}
