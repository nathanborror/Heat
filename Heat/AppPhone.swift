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
    @Environment(\.dismissWindow) private var dismissWindow

    // Providers
    private let agentsProvider = AgentsProvider.shared
    private let conversationsProvider = ConversationsProvider.shared
    private let messagesProvider = MessagesProvider.shared
    private let preferencesProvider = PreferencesProvider.shared

    @State private var selectedConversationID: String? = nil
    @State private var sheet: Sheet? = nil

    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        var id: String { rawValue }
    }

    var body: some Scene {
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
    }

    func handleInit() {
        handleReset()
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
}
