/*
 ___   ___   ______   ________   _________
/__/\ /__/\ /_____/\ /_______/\ /________/\
\::\ \\  \ \\::::_\/_\::: _  \ \\__.::.__\/
 \::\/_\ .\ \\:\/___/\\::(_)  \ \  \::\ \
  \:: ___::\ \\::___\/_\:: __  \ \  \::\ \
   \: \ \\::\ \\:\____/\\:.\ \  \ \  \::\ \
    \__\/ \::\/ \_____\/ \__\/\__\/   \__\/
 */

import SwiftUI
import SwiftData
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) var scenePhase
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    @State private var store = Store.shared
    @State private var conversationViewModel = ConversationViewModel(store: Store.shared)
    
    var body: some Scene {
        #if os(macOS)
        Window("Heat", id: "heat") {
            NavigationSplitView {
                ConversationList()
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                ConversationView()
                    #if !os(macOS)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: handleNewConversation) {
                                Label("New Conversation", systemImage: "plus")
                            }
                        }
                    }
                    #endif
            }
            .environment(store)
            .environment(conversationViewModel)
            .task(id: scenePhase) {
                handlePhaseChange()
            }
            .task {
                handleRestore()
            .modelContainer(for: Memory.self)
            }
        }
        .defaultSize(width: 600, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation", action: handleNewConversation)
                    .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            NavigationStack {
                PreferencesWindow()
            }
            .frame(width: 600)
            .environment(store)
        }
        #else
        WindowGroup {
            MainCompactView()
                .environment(store)
                .environment(conversationViewModel)
                .modelContainer(for: Memory.self)
                .task(id: scenePhase) {
                    handlePhaseChange()
                }
                .task {
                    handleRestore()
                }
        }
        #endif
    }
    
    func handlePhaseChange() {
        #if os(macOS)
        guard scenePhase == .inactive else { return }
        #else
        guard scenePhase == .background else { return }
        #endif
        handleSave()
    }
    
    func handleRestore() {
        Task {
            do {
                try await store.restore()
            } catch {
                logger.warning("failed to restore: \(error)")
            }
        }
    }
    
    func handleSave() {
        Task { try await store.saveAll() }
    }
    
    func handleNewConversation() {
        conversationViewModel.conversationID = nil
    }
}
