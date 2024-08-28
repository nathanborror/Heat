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
import HotKey
import CoreServices
import EventKit
import SharedKit
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    private let agentsProvider = AgentsProvider.shared
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared
    
    @State private var conversationViewModel = ConversationViewModel()
    @State private var searchInput = ""
    @State private var showingLauncher = false
    @State private var showingPreferences = false
    
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
                    .toolbar {
                        ToolbarItem {
                            Button {
                                showingPreferences.toggle()
                            } label: {
                                Label("Preferences", systemImage: "slider.horizontal.3")
                            }
                        }
                        ToolbarItem {
                            Button {
                                Task { try await conversationViewModel.newConversation() }
                            } label: {
                                Label("New Conversation", systemImage: "plus")
                            }
                        }
                    }
            }
            .sheet(isPresented: $showingPreferences) {
                NavigationStack {
                    PreferencesForm(preferences: preferencesProvider.preferences)
                }
            }
            .onAppear {
                handleInit()
            }
            .floatingPanel(isPresented: $showingLauncher) {
                LauncherView()
                    .environment(agentsProvider)
                    .environment(conversationsProvider)
                    .environment(messagesProvider)
                    .environment(preferencesProvider)
                    .environment(conversationViewModel)
                    .environment(\.debug, preferencesProvider.preferences.debug)
                    .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
                    .modelContainer(for: Memory.self)
            }
        }
        .environment(agentsProvider)
        .environment(conversationsProvider)
        .environment(messagesProvider)
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
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...", action: handleShowPreferences)
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            MainCompactView()
                .environment(agentsProvider)
                .environment(conversationsProvider)
                .environment(messagesProvider)
                .environment(preferencesProvider)
                .environment(conversationViewModel)
                .environment(\.debug, preferencesProvider.preferences.debug)
                .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
                .modelContainer(for: Memory.self)
                .onAppear {
                    handleInit()
                }
        }
        #endif
    }
    
    func handleInit() {
        handleReset()
        handleHotKeySetup()
    }
    
    func handleReset() {
        if BundleVersion.shared.isBundleVersionNew() {
            Task {
                try await agentsProvider.reset()
                try await conversationsProvider.reset()
                try await messagesProvider.reset()
                try await preferencesProvider.reset()
            }
        }
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
    
    func handleShowPreferences() {
        showingPreferences.toggle()
    }
}
