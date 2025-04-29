import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "DocumentViewModel", category: "App")

@Observable @MainActor
final class DocumentViewModel {
    var file: File
    var document: Document = .init()

    var editorManager = MagicEditorManager()
    var contextMenuManager = MagicContextMenuManager()

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

    var title: String {
        file.name ?? "Heat"
    }

    var subtitle: String {
        guard let (_, model) = try? API.shared.preferredChatService() else { return "Unknown model" }
        return model.name ?? model.id
    }

    init(file: File) {
        self.file = file

        contextMenuManager.options = [
            .init(label: "User") {
                self.editorManager.backspace()
                self.handleInsert(role: "user")
            },
            .init(label: "Assistant") {
                self.editorManager.backspace()
                self.handleInsert(role: "assistant")
            },
            .init(label: "System") {
                self.editorManager.backspace()
                self.handleInsert(role: "system")
            }
        ]
    }

    func read(_ document: Document) {
        self.document = document
        editorManager.read(document: document)
    }

    func handleGenerate() async throws {
        var document = try editorManager.encode()

        // Encode messages from document
        let messages = document.encodeMessages()

        // Insert assistant marker
        editorManager.insert(text: "\n\n")
        handleInsert(role: "assistant")

        let location = editorManager.selectedRange.location
        var content = ""

        let (service, model) = try API.shared.preferredChatService()

        var context: [String: Value] = [:]
        context["DATETIME"] = .string(Date.now.formatted())

        document.state = .processing

        // Initial request
        var req = ChatSessionRequest(service: service, model: model)
        req.with(history: messages)

        // Generate response stream
        let stream = ChatSession.shared.stream(req)
        for try await message in stream {
            try Task.checkCancellation()

            let delta = String(message.content?.trimmingPrefix(content) ?? "")
            editorManager.insert(text: delta, at: location + content.count)
            content = message.content ?? content
        }

        let finalLocation = location + content.count
        editorManager.insert(text: "\n\n", at: finalLocation)
        editorManager.selectedRange = .init(location: finalLocation+2, length: 0)
        handleInsert(role: "user")

        // Reset conversation state
        document.state = .none

        // Generate title
        try await generateTitle()

        // Cache conversation
        try await API.shared.fileUpdate(file.id, object: document)
        try await API.shared.fileUpdate(file)
    }

    func generateTitle() async throws {
        guard file.name == nil else { return }

        let (service, model) = try API.shared.preferredChatService()

        // Flatted message history
        let messages = document.encodeMessages()
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

            file.name = tag?.content
            file.modified = .now
        }
    }

    func handleInsert(role: String) {
        let attachment = RoleAttachment(role: role)
        editorManager.insert(attachment: attachment)
        editorManager.insert(text: "\n")
        editorManager.showingContextMenu = false
    }

    func cancel() {
        generateTask?.cancel()
    }

    // MARK: - Private

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
