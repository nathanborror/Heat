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
    @State private var conversationID: String?
    
    var body: some Scene {
        #if os(macOS)
        Window("Heat", id: "heat") {
            NavigationSplitView {
                ConversationList(selection: $conversationID)
                    .environment(store)
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                ConversationView(conversationID: $conversationID)
                    .environment(store)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: { conversationID = nil }) {
                                Label("New Conversation", systemImage: "plus")
                            }
                        }
                    }
            }
            .onChange(of: scenePhase) { _, _ in
                handlePhaseChange()
            }
            .onAppear {
                handleRestore()
            }
        }
        .defaultSize(width: 600, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    conversationID = nil
                }
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
            MainCompactView(conversationID: $conversationID)
                .environment(store)
                .onChange(of: scenePhase) { _, _ in
                    handlePhaseChange()
                }
                .onAppear {
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
}
