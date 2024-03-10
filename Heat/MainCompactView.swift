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
                    switch sheet {
                    case .preferences:
                        NavigationStack {
                            PreferencesForm()
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") { self.sheet = nil }
                                    }
                                }
                        }
                        .environment(store)
                    case .conversationList:
                        NavigationStack {
                            ConversationList()
                        }
                        .environment(store)
                        .environment(conversationViewModel)
                        .presentationDetents([.medium, .large])
                    }
                }
        }
    }
}

#Preview {
    MainCompactView()
        .environment(Store.preview)
        .environment(ConversationViewModel(store: Store.preview))
}
