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

    @State private var showingError = false
    @State private var error: (any CustomStringConvertible)? = nil

    var body: some Scene {
        Window("Heat", id: "heat") {
            NavigationSplitView {
                FileList(selected: $state.selectedFileID)
                    .frame(minWidth: 200)
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                if let fileID = state.selectedFileID {
                    FileDetail(fileID: fileID)
                } else {
                    ContentUnavailableView("No file selected", systemImage: "doc.plaintext")
                }
            }
            .containerBackground(.background, for: .window)
            .toolbar {
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
                    .menuIndicator(.hidden)
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.description)
            }
            .onAppear {
                Task { await appReady() }
            }
        }
        .defaultSize(width: 600, height: 700)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.presented)
        .environment(state)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Reset") {
                    Task { await appActive() }
                }
            }
        }

        Settings {
            PreferencesView()
                .frame(minWidth: 600)
        }
        .environment(state)
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
