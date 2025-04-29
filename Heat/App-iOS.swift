import SwiftUI
import OSLog
import CoreServices
import EventKit
import SharedKit
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "App")

@main
struct MainApp: App {
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var state = AppState.shared

    @State private var selectedConversationID: String? = nil
    @State private var sheet: Sheet? = nil

    @State private var showingError = false
    @State private var error: (any CustomStringConvertible)? = nil

    enum Sheet: String, Identifiable {
        case files
        case settings
        var id: String { rawValue }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if let fileID = state.selectedFileID {
                        FileDetail(fileID: fileID)
                    } else {
                        ContentUnavailableView("No file selected", systemImage: "doc.plaintext")
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Menu {
                            Button("Files") {
                                sheet = .files
                            }
                            Button("Settings") {
                                sheet = .settings
                            }
                            Divider()
                            Button("Reset All Data") {
                                Task { await appReset() }
                            }
                        } label: {
                            Label("Menu", systemImage: "ellipsis")
                        }
                    }

                    ToolbarItem {
                        Menu {
                            Button("New Conversation") {
                                Task { try await state.fileCreateConversation() }
                            }
                            Button("New Document") {
                                Task { try await state.fileCreateDocument() }
                            }
                            Button("New Folder") {
                                Task { try await state.folderCreate() }
                            }
                        } label: {
                            Label("New File", systemImage: "plus")
                        }
                    }
                }
                .sheet(item: $sheet) { sheet in
                    NavigationStack {
                        switch sheet {
                        case .settings:
                            SettingsView()
                        case .files:
                            FileList(selected: $state.selectedFileID)
                        }
                    }
                }
            }
            .environment(state)
            .onAppear {
                Task { await appActive() }
            }
        }
    }

    func appActive() async {
        do {
            try await state.ready()
        } catch {
            state.log(error: error)
        }
    }

    func appReset() async {
        state.resetAll()
        await appActive()
    }
}
