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
import HotKey
import CoreServices
import EventKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) var scenePhase
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    @State private var store = Store.shared
    @State private var conversationViewModel = ConversationViewModel(store: .shared)
    @State private var launcherViewModel = LauncherViewModel(store: .shared)
    
    @State private var searchInput = ""
    @State private var showingLauncher = false
    @State private var showingBarrier = false
    @State private var isRestoring = false
    
    #if os(macOS)
    private let hotKey = HotKey(key: .space, modifiers: [.shift, .control])
    #endif
    
    var body: some Scene {
        #if os(macOS)
        Window("Heat", id: "heat") {
            NavigationSplitView {
                ConversationList()
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                ConversationView()
            }
            .environment(store)
            .environment(conversationViewModel)
            .modelContainer(for: Memory.self)
            .task {
                handleHotKeySetup()
            }
            .task(id: store.isChatAvailable) {
                handleAvailabilityChange()
            }
            .sheet(isPresented: $showingBarrier) {
                ConversationBarrier()
                    .frame(width: 300, height: 325)
                    .environment(store)
            }
            .floatingPanel(isPresented: $showingLauncher) {
                LauncherView()
                    .environment(store)
                    .environment(launcherViewModel)
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
                .task(id: store.isChatAvailable) {
                    handleAvailabilityChange()
                }
                .sheet(isPresented: $showingBarrier) {
                    ConversationBarrier()
                        .environment(store)
                }
        }
        #endif
    }
    
    func handleAvailabilityChange() {
        guard !isRestoring else { return }
        showingBarrier = !store.isChatAvailable
    }
    
    func handleNewConversation() {
        conversationViewModel.conversationID = nil
    }
    
    func handleHotKeySetup() {
        #if os(macOS)
        hotKey.keyDownHandler = {
            showingLauncher.toggle()
        }
        #endif
    }
}
