import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var filterQuery = ""
    
    var filteredConversations: [Conversation] {
        if filterQuery.isEmpty {
            return store.conversations
        }
        return store.conversations
            .filter { conversation in
                conversation.title.lowercased().contains(filterQuery.lowercased())
            }
    }
    
    var body: some View {
        @Bindable var conversationViewModel = conversationViewModel
        List(selection: $conversationViewModel.conversationID) {
            Section {
                ForEach(filteredConversations) { conversation in
                    VStack(alignment: .leading) {
                        Text(conversation.title)
                    }
                    .tag(conversation.id)
                    .swipeActions {
                        Button(role: .destructive, action: { store.delete(conversationID: conversation.id) }) {
                            Label("Trash", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("History")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .listStyle(.sidebar)
        .navigationTitle("History")
        #if os(macOS)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 0) {
                Button(action: { conversationViewModel.conversationID = nil }) {
                    Image(systemName: "plus")
                        .padding(8)
                }
                .buttonStyle(.plain)
                
                TextField("Filter", text: $filterQuery)
                    .padding(.trailing, 8)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.vertical, 2)
        }
        #endif
    }
}

#Preview {
    NavigationStack {
        ConversationList()
    }
    .environment(Store.preview)
    .environment(ConversationViewModel(store: Store.preview))
}
