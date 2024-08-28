import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainCompactView", category: "Heat")

struct MainCompactView: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var sheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        case services
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ConversationView()
                .overlay {
                    switch preferencesProvider.status {
                    case .needsServiceSetup:
                        ContentUnavailableView {
                            Label("Missing services", systemImage: "exclamationmark.icloud")
                        } description: {
                            Text("Configure a service like OpenAI, Anthropic or Ollama to get started.")
                            Button("Open Services") { sheet = .services }
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
                                Label("New conversation", systemImage: "bubble")
                            } description: {
                                Text("Start a new conversation by typing a message.")
                            }
                        }
                    case .waiting:
                        EmptyView()
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Menu {
                            menuButton("History", symbol: "clock") { sheet = .conversationList }
                            Divider()
                            menuButton("Preferences", symbol: "slider.horizontal.3") { sheet = .preferences }
                        } label: {
                            Label("Menu", systemImage: "ellipsis")
                        }
                    }
                    ToolbarItem {
                        menuButton("New Conversation", symbol: "plus") {
                            Task { try await conversationViewModel.newConversation() }
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
                    .environment(agentsProvider)
                    .environment(conversationsProvider)
                    .environment(preferencesProvider)
                    .environment(conversationViewModel)
                    .environment(\.debug, preferencesProvider.preferences.debug)
                    .environment(\.useMarkdown, preferencesProvider.preferences.shouldUseMarkdown)
                    .modelContainer(for: Memory.self)
                }
        }
    }
    
    func menuButton(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
        }
    }
}
