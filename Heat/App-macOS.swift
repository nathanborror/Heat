import SwiftUI
import OSLog
import CoreServices
import EventKit
import SharedKit
import HeatKit
import KeyboardShortcuts

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
                ConversationView(fileID: $state.selectedFileID)
            }
            .containerBackground(.background, for: .window)
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
                    Task { await appReset() }
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

    func appReady() async {
        do {
            try await state.ping()
        } catch {
            state.log(error: error)
        }
    }

    func appReset() async {
        state.resetAll()
        await appReady()
    }
}
