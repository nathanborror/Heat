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
    
    @State private var store = Store.shared
    @State private var conversationViewModel = ConversationViewModel(store: Store.shared)
    
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            NavigationStack {
                ConversationView()
            }
            .environment(store)
            .environment(conversationViewModel)
            .onChange(of: scenePhase) { _, _ in
                handlePhaseChange()
            }
            .onAppear {
                handleRestore()
                NSWindow.allowsAutomaticWindowTabbing = false
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 450, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    print("not implemented")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(before: .windowList) {
                Button("Show History") {
                    print("not implemented")
                }
                .keyboardShortcut("h", modifiers: [.shift, .command])
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
