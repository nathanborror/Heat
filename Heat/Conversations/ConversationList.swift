import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var conversationViewModel = conversationViewModel
        List(selection: $conversationViewModel.conversationID) {
            Section {
                ForEach(store.conversations) { conversation in
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
        }
        #else
        .onChange(of: conversationViewModel.conversationID) { _, _ in
            guard conversationViewModel.conversationID != nil else { return }
            dismiss()
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
