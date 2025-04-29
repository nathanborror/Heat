import SwiftUI
import GenKit
import SharedKit
import HeatKit

struct DocumentView: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State private var editorManager = MagicEditorManager()
    @State private var contextMenuManager = MagicContextMenuManager()

    var body: some View {
        ZStack(alignment: .topLeading) {
            MagicEditor(viewModel: $editorManager)

            if editorManager.showingContextMenu {
                MagicContextMenu(manager: contextMenuManager)
                    .frame(width: 150)
                    .offset(x: editorManager.contextMenuPosition.x, y: editorManager.contextMenuPosition.y)
            }
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("User") {
                        handleInsert(role: "user")
                    }
                    Button("Assistant") {
                        handleInsert(role: "assistant")
                    }
                    Button("System") {
                        handleInsert(role: "system")
                    }
                } label: {
                    Label("Insert", systemImage: "paperclip")
                }
                .menuIndicator(.hidden)
            }
            ToolbarItem {
                Button {
                    editorManager.bold()
                } label: {
                    Label("Bold", systemImage: "bold")
                }
            }
            ToolbarItem {
                Button {
                    Task { try await handleGenerate() }
                } label: {
                    Label("Submit", systemImage: "arrow.up")
                }
            }
        }
        .onChange(of: editorManager.contextMenuNotification) { _, newValue in
            switch newValue?.kind {
            case .submit:
                Task { try await handleGenerate() }
            case .up:
                contextMenuManager.handleSelectionMoveUp()
            case .down:
                contextMenuManager.handleSelectionMoveDown()
            case .select:
                contextMenuManager.handleSelection()
            case .none:
                break
            }
        }
        .onAppear {
            handleLoad()
        }
        .onDisappear {
            handleSave()
        }
    }

    func handleLoad() {
        Task {
            do {
                let document = try await API.shared.fileData(fileID, type: Document.self)
                editorManager.read(document: document)

                // Set context menu options
                contextMenuManager.options = [
                    .init(label: "User") {
                        editorManager.backspace()
                        handleInsert(role: "user")
                    },
                    .init(label: "Assistant") {
                        editorManager.backspace()
                        handleInsert(role: "assistant")
                    },
                    .init(label: "System") {
                        editorManager.backspace()
                        handleInsert(role: "system")
                    }
                ]
            } catch {
                state.log(error: error)
            }
        }
    }

    func handleSave() {
        do {
            let document = try editorManager.encode()
            Task { try await API.shared.fileUpdate(fileID, object: document) }
        } catch {
            state.log(error: error)
        }
    }

    func handleInsert(role: String) {
        let attachment = RoleAttachment(role: role)
        editorManager.insert(attachment: attachment)
        editorManager.insert(text: "\n")
        editorManager.showingContextMenu = false
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

        // Cache conversation
        try await API.shared.fileUpdate(fileID, object: document)
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
