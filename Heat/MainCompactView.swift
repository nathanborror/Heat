import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainCompactView", category: "Heat")

struct MainCompactView: View {
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var sheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case conversationList
        case memories
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
                            menuButton("Memory", symbol: "brain") { sheet = .memories }
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
                            PreferencesForm(
                                preferences: PreferencesProvider.shared.preferences,
                                services: PreferencesProvider.shared.services
                            )
                        case .memories:
                            MemoryList()
                        case .conversationList:
                            ConversationList()
                        }
                    }
                    .environment(conversationViewModel)
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
