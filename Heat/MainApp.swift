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
import CoreServices
import EventKit
import SharedKit
import HeatKit
import KeyboardShortcuts

private let logger = Logger(subsystem: "MainApp", category: "App")

@main
struct MainApp: App {
    @Environment(\.openWindow) var openWindow
    
    // Providers
    private let agentsProvider = AgentsProvider.shared
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared
    
    @State private var selectedConversationID: String? = nil
    @State private var showingLauncher = false
    @State private var sheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        var id: String { rawValue }
    }
    
    var body: some Scene {
        #if os(macOS)
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
                        PreferencesForm(preferences: preferencesProvider.preferences)
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
        .environment(agentsProvider)
        .environment(conversationsProvider)
        .environment(messagesProvider)
        .environment(preferencesProvider)
        .environment(\.debug, preferencesProvider.preferences.debug)
        .environment(\.textRendering, preferencesProvider.preferences.textRendering)
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
            List {
                Text("Hello")
                Text("World")
            }
        }
        .windowManagerRole(.associated)
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 400)
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
        #else
        WindowGroup {
            NavigationStack {
                ConversationView(selected: $selectedConversationID)
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
                    }
                    .sheet(item: $sheet) { sheet in
                        NavigationStack {
                            switch sheet {
                            case .preferences:
                                PreferencesForm(preferences: preferencesProvider.preferences)
                            case .conversationList:
                                ConversationList(selected: $selectedConversationID)
                            }
                        }
                    }
            }
            .environment(agentsProvider)
            .environment(conversationsProvider)
            .environment(messagesProvider)
            .environment(preferencesProvider)
            .environment(\.debug, preferencesProvider.preferences.debug)
            .environment(\.textRendering, preferencesProvider.preferences.textRendering)
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
                
                try await preferencesProvider.initializeServices()
            }
        }
    }
    
    func handleHotKeySetup() {
        #if os(macOS)
        KeyboardShortcuts.onKeyUp(for: .toggleLauncher) { [self] in
            openWindow(id: "launcher")
            showingLauncher.toggle()
        }
        #endif
    }
}

#if os(macOS)
extension KeyboardShortcuts.Name {
    static let toggleLauncher = Self("toggleLauncher", default: .init(.h, modifiers: [.shift, .command]))
}
#endif
