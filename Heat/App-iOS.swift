import SwiftUI
import SwiftData
import OSLog
import CoreServices
import EventKit
import SharedKit
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "App")

@main
struct MainApp: App {
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var state = AppState.development

    @State private var selectedConversationID: Conversation.ID? = nil
    @State private var sheet: Sheet? = nil

    @State private var showingError = false
    @State private var error: (any CustomStringConvertible)? = nil

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
                                PreferencesForm(preferences: state.preferencesProvider.preferences)
                            case .conversationList:
                                ConversationList(selected: $selectedConversationID)
                            }
                        }
                    }
            }
            .environment(state)
            .modelContainer(for: Memory.self)
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.description)
            }
            .onAppear {
                handleInit()
            }
        }
    }

    func handleInit() {
        handleReset()
    }

    func handleReset(_ force: Bool = false) {
        if BundleVersion.shared.isBundleVersionNew() || force {
            Task { try await state.reset() }
        }
    }
}
