import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainCompactView", category: "Heat")

struct MainCompactView: View {
    @Environment(Store.self) var store
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
                        menuButton("New Conversation", symbol: "plus") { conversationViewModel.conversationID = nil }
                    }
                }
                .sheet(item: $sheet) { sheet in
                    NavigationStack {
                        switch sheet {
                        case .preferences:      PreferencesForm()
                        case .memories:         MemoryList()
                        case .conversationList: ConversationList()
                        }
                    }
                    .environment(store)
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

#Preview {
    MainCompactView()
        .environment(Store.preview)
        .environment(ConversationViewModel(store: Store.preview))
}
