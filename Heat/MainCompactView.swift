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
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                Menu {
                    Button(action: { viewModel.conversationID = nil }) {
                        Label("New Conversation", systemImage: "plus")
                    }
                    Button(action: { self.sheet = .conversationList }) {
                        Label("History", systemImage: "clock")
                    }
                    Button(action: { self.sheet = .preferences }) {
                        Label("Preferences", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 10))
                        .tint(.secondary)
                }
            }
            .padding()
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

#Preview {
    MainCompactView()
        .environment(Store.preview)
        .environment(ConversationViewModel(store: Store.preview))
}
