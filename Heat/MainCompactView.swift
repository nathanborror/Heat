import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainCompactView", category: "Heat")

struct MainCompactView: View {
    @Environment(Store.self) var store
    
    @Binding var conversationID: String?
    
    @State private var sheet: Sheet? = nil
    
    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ConversationView(conversationID: $conversationID)
                .toolbar {
                    Menu {
                        Button(action: { conversationID = nil }) {
                            Label("New Conversation", systemImage: "plus")
                        }
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
                            ConversationList(selection: $conversationID)
                        }
                        .environment(store)
                        .presentationDetents([.medium, .large])
                    }
                }
        }
    }
}

#Preview {
    MainCompactView(conversationID: .constant(nil))
        .environment(Store.preview)
}
