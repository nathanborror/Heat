import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    var body: some View {
        @Bindable var conversationViewModel = conversationViewModel
        List(selection: $conversationViewModel.conversationID) {
            ForEach(store.conversations) { conversation in
                VStack(alignment: .leading) {
                    Text(conversation.title)
                    Text(conversation.messages.last?.content ?? "None")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .tag(conversation.id)
                .swipeActions {
                    Button(role: .destructive, action: { store.delete(conversationID: conversation.id) }) {
                        Label("Trash", systemImage: "trash")
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .listStyle(.sidebar)
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack {
        ConversationList()
    }
    .environment(Store.preview)
    .environment(ConversationViewModel(store: Store.preview))
}
