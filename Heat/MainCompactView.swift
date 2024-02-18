import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainCompactView", category: "Heat")

struct MainCompactView: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) private var viewModel
    
    enum Sheet: String, Identifiable {
        case conversationList
        case preferences
        var id: String { rawValue }
    }
    
    @State var sheet: Sheet? = nil
    
    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ConversationView()
                .toolbar {
                    Menu {
                        Button(action: {}) {
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
                            ConversationList()
                        }
                        .environment(store)
                        .environment(viewModel)
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
