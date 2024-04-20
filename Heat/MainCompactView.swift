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
                            Button(action: { sheet = .conversationList }) {
                                Label("History", systemImage: "clock")
                            }
                            Button(action: { sheet = .memories }) {
                                Label("Memory", systemImage: "brain")
                            }
                            Divider()
                            Button(action: { sheet = .preferences }) {
                                Label("Preferences", systemImage: "slider.horizontal.3")
                            }
                        } label: {
                            Label("Menu", systemImage: "ellipsis")
                        }
                    }
                    ToolbarItem {
                        Button(action: { conversationViewModel.conversationID = nil }) {
                            Label("New Conversation", systemImage: "plus")
                        }
                    }
                }
                .sheet(item: $sheet) { sheet in
                    NavigationStack {
                        switch sheet {
                        case .preferences:
                            PreferencesForm()
                        case .memories:
                            MemoryList()
                        case .conversationList:
                            ConversationList()
                        }
                    }
                    .environment(store)
                    .environment(conversationViewModel)
                    .presentationDragIndicator(.visible)
                }
        }
    }
}

#Preview {
    MainCompactView()
        .environment(Store.preview)
        .environment(ConversationViewModel(store: Store.preview))
}
