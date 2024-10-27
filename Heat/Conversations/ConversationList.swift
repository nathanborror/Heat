import HeatKit
import SwiftUI

struct ConversationList: View {
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(\.dismiss) private var dismiss

    @Binding var selected: String?

    var body: some View {
        List(selection: $selected) {
            Section {
                ForEach(conversationsProvider.conversations) { conversation in
                    VStack(alignment: .leading) {
                        Text(conversation.title ?? "Untitled")
                    }
                    .tag(conversation.id)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { try await conversationsProvider.delete(conversation.id) }
                        } label: {
                            Label("Trash", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("History")
        #if os(iOS)
        .onChange(of: selected) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .overlay {
            if conversationsProvider.conversations.isEmpty {
                ContentUnavailableView {
                    Label("Conversation history", systemImage: "clock")
                } description: {
                    Text("Your history is empty.")
                }
            }
        }
        #endif
    }
}
