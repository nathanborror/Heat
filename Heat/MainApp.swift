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
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    private let agentsProvider = AgentsProvider.shared
    private let conversationsProvider = ConversationsProvider.shared
    private let preferencesProvider = PreferencesProvider.shared
    
    @State private var conversationViewModel = ConversationViewModel()
    @State private var searchInput = ""
    @State private var showingLauncher = false
    @State private var showingBarrier = false
    
    #if os(macOS)
    private let hotKey = HotKey(key: .space, modifiers: [.option])
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
            .task {
                handleHotKeySetup()
            }
            .sheet(isPresented: $showingBarrier) {
                ConversationBarrier()
                    .frame(width: 300, height: 325)
            }
            .floatingPanel(isPresented: $showingLauncher) {
                LauncherView()
                    .environment(agentsProvider)
                    .environment(conversationsProvider)
                    .environment(preferencesProvider)
                    .environment(conversationViewModel)
                    .environment(\.debug, preferencesProvider.preferences.debug)
                    .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
                    .modelContainer(for: Memory.self)
            }
        }
        .environment(agentsProvider)
        .environment(conversationsProvider)
        .environment(preferencesProvider)
        .environment(conversationViewModel)
        .environment(\.debug, preferencesProvider.preferences.debug)
        .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
        .modelContainer(for: Memory.self)
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
            .environment(agentsProvider)
            .environment(conversationsProvider)
            .environment(preferencesProvider)
            .modelContainer(for: Memory.self)
        }
        #else
        WindowGroup {
            MainCompactView()
                .environment(agentsProvider)
                .environment(conversationsProvider)
                .environment(preferencesProvider)
                .environment(conversationViewModel)
                .environment(\.debug, preferencesProvider.preferences.debug)
                .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
                .modelContainer(for: Memory.self)
                .sheet(isPresented: $showingBarrier) {
                    ConversationBarrier()
                }
        }
        #endif
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
