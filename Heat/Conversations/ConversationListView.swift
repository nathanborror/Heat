import SwiftUI
import HeatKit

struct ConversationListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let selection: (String) -> Void
    
    var body: some View {
        List {
            ForEach(store.conversations) { conversation in
                Button(action: { handleSelection(conversation) }) {
                    ConversationRow(conversation: conversation)
                }
                .buttonStyle(.plain)
                .tint(.primary)
                .swipeActions {
                    Button(role: .destructive, action: { handleDelete(conversation) }) {
                        Image(systemName: "trash")
                    }
                    Button(action: { handleShowInfo(conversation) }) {
                        Image(systemName: "info")
                    }
                }
            }
        }
        .navigationTitle("History")
        .frame(idealWidth: 400, idealHeight: 400)
        .toolbar {
            ToolbarItem {
                Button(action: { dismiss() }) {
                    Text("Done")
                }
            }
        }
    }
    
    func handleSelection(_ conversation: Conversation) {
        selection(conversation.id)
        dismiss()
    }
    
    func handleDelete(_ conversation: Conversation) {
        store.delete(conversation: conversation)
    }
    
    func handleShowInfo(_ conversation: Conversation) {
        print("not implemented")
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("New Conversation")
            Text(conversation.messages.last?.content ?? "Say something...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    #if os(macOS)
    private let pictureSize: CGFloat = 32
    #else
    private let pictureSize: CGFloat = 54
    #endif
}

#Preview {
    let store = Store.preview
    return NavigationStack {
        ConversationListView(selection: {_ in})
    }
    .environment(store)
}
