import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(store.conversations) { conversation in
                VStack(alignment: .leading) {
                    Text(conversation.title)
                    Text(conversation.messages.last?.content ?? "None")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .swipeActions {
                    Button(role: .destructive, action: { store.delete(conversationID: conversation.id) }) {
                        Label("Trash", systemImage: "trash")
                    }
                }
                .onTapGesture {
                    viewModel.conversationID = conversation.id
                    dismiss()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .listStyle(.plain)
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
