import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(Store.self) var store
    
    @Binding var selection: String?
    
    var body: some View {
        List(selection: $selection) {
            ForEach(store.conversations) { conversation in
                NavigationLink(value: conversation.id) {
                    VStack(alignment: .leading) {
                        Text(conversation.title)
                        Text(conversation.messages.last?.content ?? "None")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
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
        ConversationList(selection: .constant(""))
    }
    .environment(Store.preview)
}
