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
    
    let store: Store
    let conversationViewModel: ConversationViewModel
    let launcherViewModel: LauncherViewModel
    
    @State private var searchInput = ""
    @State private var showingLauncher = false
    @State private var showingBarrier = false
    @State private var isRestoring = false
    
    #if os(macOS)
    private let hotKey = HotKey(key: .space, modifiers: [.shift, .control])
    #endif
    
    init() {
        self.store = Store.shared
        self.conversationViewModel = ConversationViewModel(store: store)
        self.launcherViewModel = LauncherViewModel(store: store)
    }
    
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
                await handleRestore()
                handleHotKeySetup()
            }
            .task(id: scenePhase) {
                handlePhaseChange()
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
                .task(id: scenePhase) {
                    handlePhaseChange()
                }
                .task(id: store.isChatAvailable) {
                    handleAvailabilityChange()
                }
                .task {
                    await handleRestore()
                }
                .sheet(isPresented: $showingBarrier) {
                    ConversationBarrier()
                        .environment(store)
                }
        }
        #endif
    }
    
    func handlePhaseChange() {
        guard !isRestoring else { return }
        #if os(macOS)
        guard scenePhase == .inactive else { return }
        #else
        guard scenePhase == .background else { return }
        #endif
        handleSave()
    }
    
    func handleAvailabilityChange() {
        guard !isRestoring else { return }
        // TODO:
//        showingBarrier = !store.isChatAvailable
    }
    
    func handleRestore() async {
        do {
            isRestoring = true
            try await store.restoreAll()
            // TODO:
//            showingBarrier = !store.isChatAvailable
            isRestoring = false
        } catch {
            logger.warning("failed to restore: \(error)")
        }
    }
    
    func handleSave() {
        Task { try await store.saveAll() }
    }
    
    func handleNewConversation() {
        // TODO: 
//        conversationViewModel.conversationID = nil
    }
    
    func handleHotKeySetup() {
        #if os(macOS)
        hotKey.keyDownHandler = {
            showingLauncher.toggle()
        }
        #endif
    }
}
