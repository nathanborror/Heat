import SwiftUI
import GenKit
import SharedKit
import HeatKit

struct DocumentView: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State var documentViewModel: DocumentViewModel

    init(file: File) {
        self.fileID = file.id
        self.documentViewModel = .init(file: file)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            MagicEditor(viewModel: $documentViewModel.editorManager)

            if documentViewModel.editorManager.showingContextMenu {
                MagicContextMenu(manager: documentViewModel.contextMenuManager)
                    .frame(width: 150)
                    .offset(
                        x: documentViewModel.editorManager.contextMenuPosition.x,
                        y: documentViewModel.editorManager.contextMenuPosition.y
                    )
            }
        }
        .navigationTitle(documentViewModel.title)
        #if os(macOS)
        .navigationSubtitle(documentViewModel.subtitle)
        .padding()
        #endif
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("User") {
                        documentViewModel.handleInsert(role: "user")
                    }
                    Button("Assistant") {
                        documentViewModel.handleInsert(role: "assistant")
                    }
                    Button("System") {
                        documentViewModel.handleInsert(role: "system")
                    }
                } label: {
                    Label("Insert", systemImage: "paperclip")
                }
                .menuIndicator(.hidden)
            }
            ToolbarItem {
                Button {
                    documentViewModel.editorManager.bold()
                } label: {
                    Label("Bold", systemImage: "bold")
                }
            }
            ToolbarItem {
                Button {
                    Task { try await documentViewModel.handleGenerate() }
                } label: {
                    Label("Submit", systemImage: "arrow.up")
                }
            }
        }
        .onChange(of: documentViewModel.editorManager.contextMenuNotification) { _, newValue in
            switch newValue?.kind {
            case .submit:
                Task { try await documentViewModel.handleGenerate() }
            case .up:
                documentViewModel.contextMenuManager.handleSelectionMoveUp()
            case .down:
                documentViewModel.contextMenuManager.handleSelectionMoveDown()
            case .select:
                documentViewModel.contextMenuManager.handleSelection()
            case .none:
                break
            }
        }
        .onChange(of: fileID) { oldValue, newValue in
            handleLoad()
        }
        .onAppear {
            handleLoad()
        }
        .onDisappear {
            handleSave()
        }
    }

    func handleLoad() {
        do {
            let document = try state.file(Document.self, fileID: fileID)
            documentViewModel.read(document)
        } catch {
            state.log(error: error)
        }
    }

    func handleSave() {
        do {
            let document = try documentViewModel.editorManager.encode()
            Task { try await API.shared.fileUpdate(fileID, object: document) }
        } catch {
            state.log(error: error)
        }
    }
}
