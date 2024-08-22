import SwiftUI
import HeatKit

struct ConversationList: View {
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var conversationViewModel = conversationViewModel
        List(selection: $conversationViewModel.conversationID) {
            Section {
                ForEach(ConversationProvider.shared.conversations) { conversation in
                    VStack(alignment: .leading) {
                        Text(conversation.title ?? "Untitled")
                    }
                    .tag(conversation.id)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { try await ConversationProvider.shared.delete(conversation.id) }
                        } label: {
                            Label("Trash", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .listStyle(.sidebar)
        .navigationTitle("History")
        #if !os(macOS)
        .onChange(of: conversationViewModel.conversationID) { _, _ in
            guard conversationViewModel.conversationID != nil else { return }
            dismiss()
        }
        #endif
    }
}
