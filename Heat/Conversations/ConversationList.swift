import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var selected: String? = nil
    
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
        .onChange(of: selected) { _, newValue in
            conversationViewModel.conversationID = newValue
            
            #if os(iOS)
            if newValue != nil { dismiss() }
            #endif
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
    }
}
