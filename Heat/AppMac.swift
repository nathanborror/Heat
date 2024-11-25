import SwiftUI
import SwiftData
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

    @State private var selectedConversationID: String? = nil
    @State private var showingLauncher = false
    @State private var sheet: Sheet? = nil
    @State private var launcherPanel: LauncherPanel? = nil

    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        var id: String { rawValue }
    }

    var body: some Scene {
        Window("Heat", id: "heat") {
            NavigationSplitView {
                ConversationList(selected: $selectedConversationID)
                    .frame(minWidth: 200)
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                ConversationView(selected: $selectedConversationID)
            }
            .containerBackground(.background, for: .window)
            .sheet(item: $sheet) { sheet in
                NavigationStack {
                    switch sheet {
                    case .preferences:
                        PreferencesForm(preferences: state.preferencesProvider.preferences)
                    case .conversationList:
                        ConversationList(selected: $selectedConversationID)
                    }
                }
            }
            .onAppear {
                handleInit()
            }
        }
        .defaultSize(width: 600, height: 700)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.presented)
        .environment(state)
        .modelContainer(for: Memory.self)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button {
                    sheet = .preferences
                } label: {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                Button("Reset") {
                    handleReset(true)
                }
            }
        }

        Window("Setup", id: "setup") {
            Text("Setup preferences")
        }
        .windowManagerRole(.associated)
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 400)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)

        Window("Launcher", id: "launcher") {
            LauncherPanelView()
                .containerBackground(.ultraThinMaterial, for: .window)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }
        .windowManagerRole(.associated)
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 70)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)

        MenuBarExtra {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Label("Heat", systemImage: "flame.fill")
        }
    }

    func handleInit() {
        handleReset()
        handleHotKeySetup()
    }

    func handleReset(_ force: Bool = false) {
        if BundleVersion.shared.isBundleVersionNew() || force {
            Task { try await state.reset() }
        }
    }

    func handleHotKeySetup() {
        KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [self] in
            if showingLauncher {
                //dismissWindow(id: "launcher")
                hideLauncherWindow()
            } else {
                //openWindow(id: "launcher")
                showLauncherWindow()
            }
            showingLauncher.toggle()
        }
    }

    func showLauncherWindow() {
        if launcherPanel == nil {
            launcherPanel = LauncherPanel(LauncherPanelView())
        }
        if launcherPanel?.isVisible == false {
            launcherPanel?.orderFrontRegardless()
        }
    }

    func hideLauncherWindow() {
        launcherPanel?.close()
    }
}

extension KeyboardShortcuts.Name {
    static let toggleLauncher = Self("toggleLauncher", default: .init(.h, modifiers: [.shift, .command]))
}
