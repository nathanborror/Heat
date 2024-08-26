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
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ConversationView()
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
                    .presentationDragIndicator(.visible)
                }
        }
    }
    
    func menuButton(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
        }
    }
}
