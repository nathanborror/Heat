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

private let logger = Logger(subsystem: "MainApp", category: "App")

@main
struct MainApp: App {
    
    // Providers
    private let agentsProvider = AgentsProvider.shared
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared
    
    // View models
    @State private var conversationViewModel = ConversationViewModel()
    
    @State private var searchInput = ""
    @State private var showingLauncher = false
    @State private var sheet: Sheet? = nil
    
    #if os(macOS)
    private let hotKey = HotKey(key: .space, modifiers: [.option])
    #endif

    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        case services
        var id: String { rawValue }
    }
    
    var body: some Scene {
        #if os(macOS)
        Window("Heat", id: "heat") {
            NavigationSplitView {
                ConversationList()
                    .navigationSplitViewStyle(.prominentDetail)
            } detail: {
                ConversationView()
                    .overlay {
                        switch preferencesProvider.status {
                        case .needsServiceSetup:
                            ContentUnavailableView {
                                Label("Missing services", systemImage: "exclamationmark.icloud")
                            } description: {
                                Text("Configure a service like OpenAI, Anthropic or Ollama to get started.")
                                Button("Open Preferences") { sheet = .preferences }
                            }
                        case .needsPreferredService:
                            ContentUnavailableView {
                                Label("Missing chat service", systemImage: "slider.horizontal.2.square")
                            } description: {
                                Text("Open Preferences to pick a chat service to use.")
                                Button("Open Preferences") { sheet = .preferences }
                            }
                        case .ready:
                            if conversationViewModel.messages.isEmpty {
                                ContentUnavailableView {
                                    Label("New conversation", systemImage: "message")
                                }
                                .foregroundStyle(.secondary)
                            }
                        case .waiting:
                            EmptyView()
                        }
                    }
            }
            .toolbar {
                ToolbarItem {
                    preferencesButton
                }
                ToolbarItem {
                    newConversationButton
                }
            }
            .sheet(item: $sheet) { sheet in
                NavigationStack {
                    switch sheet {
                    case .preferences:
                        PreferencesForm(preferences: preferencesProvider.preferences)
                    case .services:
                        ServiceList()
                    case .conversationList:
                        ConversationList()
                    }
                }
            }
            .floatingPanel(isPresented: $showingLauncher) {
                LauncherView()
                    .environment(agentsProvider)
                    .environment(conversationsProvider)
                    .environment(messagesProvider)
                    .environment(preferencesProvider)
                    .environment(conversationViewModel)
                    .environment(\.debug, preferencesProvider.preferences.debug)
                    .environment(\.textRendering, preferencesProvider.preferences.textRendering)
                    .modelContainer(for: Memory.self)
            }
            .onAppear {
                handleInit()
            }
        }
        .environment(agentsProvider)
        .environment(conversationsProvider)
        .environment(messagesProvider)
        .environment(preferencesProvider)
        .environment(conversationViewModel)
        .environment(\.debug, preferencesProvider.preferences.debug)
        .environment(\.textRendering, preferencesProvider.preferences.textRendering)
        .modelContainer(for: Memory.self)
        .defaultSize(width: 600, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                newConversationButton
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                preferencesButton
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            NavigationStack {
                ConversationView()
                    .toolbar {
                        ToolbarItem {
                            Menu {
                                Button {
                                    sheet = .conversationList
                                } label: {
                                    Label("History", systemImage: "clock")
                                }
                                Button {
                                    sheet = .preferences
                                } label: {
                                    Label("Preferences", systemImage: "slider.horizontal.3")
                                }
                            } label: {
                                Label("Menu", systemImage: "ellipsis")
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
                    .sheet(item: $sheet) { sheet in
                        NavigationStack {
                            switch sheet {
                            case .preferences:
                                PreferencesForm(preferences: preferencesProvider.preferences)
                            case .services:
                                ServiceList()
                            case .conversationList:
                                ConversationList()
                            }
                        }
                    }
            }
            .environment(agentsProvider)
            .environment(conversationsProvider)
            .environment(messagesProvider)
            .environment(preferencesProvider)
            .environment(conversationViewModel)
            .environment(\.debug, preferencesProvider.preferences.debug)
            .environment(\.textRendering, preferencesProvider.preferences.textRendering)
            .modelContainer(for: Memory.self)
            .onAppear {
                handleInit()
            }
        }
        #endif
    }
    
    var newConversationButton: some View {
        Button {
            conversationViewModel.conversationID = nil
        } label: {
            Label("New Conversation", systemImage: "plus")
        }
    }
    
    var preferencesButton: some View {
        Button {
            sheet = .preferences
        } label: {
            Label("Preferences...", systemImage: "slider.horizontal.3")
        }
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
                
                try await preferencesProvider.initializeServices()
            }
        }
    }
    
    func handleHotKeySetup() {
        #if os(macOS)
        hotKey.keyDownHandler = {
            showingLauncher.toggle()
        }
        #endif
    }
}
