import HeatKit
import SwiftUI

struct FileList: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    
    @Binding var selected: String?

    @State private var isEditingFile = false

    var body: some View {
        List(selection: $selected) {
            ForEach(state.fileTree) { tree in
                FileRow(tree: tree, depth: 0)
                    .tag(tree.id)
            }
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #else
        .listStyle(.plain)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Files")
        #if os(macOS)
        .contextMenu(forSelectionType: String.self) { fileIDs in
            Group {
                Button("Show in Finder") { handleShowFinder(fileIDs) }
                Button("Edit") { handleEdit(fileIDs) }
                Divider()
                Button("Delete", role: .destructive) { handleDelete(fileIDs) }
            }
        }
        #endif
        .sheet(isPresented: $isEditingFile) {
            if let fileID = state.selectedFileID {
                NavigationStack {
                    FileForm(fileID: fileID)
                }
            }
        }
        .overlay(alignment: .center) {
            if state.fileTree.isEmpty {
                ContentUnavailableView {
                    Label("No files", systemImage: "doc.on.doc")
                } description: {
                    Text("New files you create will appear here.")
                }
            }
        }
        #if os(iOS)
        .onChange(of: selected) { _, newValue in
            if newValue != nil { dismiss() }
        }
        #endif
    }

    func handleShowFinder(_ fileIDs: Set<String>) {
        #if os(macOS)
        guard let fileID = fileIDs.first else { return }
        guard let file = try? API.shared.file(fileID) else { return }

        let url = URL.documentsDirectory
            .appending(path: file.path)

        if url.hasDirectoryPath {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        #endif
    }

    func handleEdit(_ fileIDs: Set<String>) {
        if let fileID = fileIDs.first {
            state.selectedFileID = fileID
            isEditingFile = true
        }
    }

    func handleDelete(_ fileIDs: Set<String>) {
        Task {
            for fileID in fileIDs {
                try await API.shared.fileDelete(fileID)
            }
        }
    }
}
