import SwiftUI
import HeatKit

struct ChatListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let selection: (String) -> Void
    
    var body: some View {
        List {
            ForEach(store.chats) { chat in
                if let agent = store.get(agentID: chat.agentID) {
                    Button(action: { handleSelection(chat) }) {
                        ChatRow(chat: chat, agent: agent)
                    }
                    .buttonStyle(.plain)
                    .tint(.primary)
                    .swipeActions {
                        Button(role: .destructive, action: { handleDelete(chat) }) {
                            Image(systemName: "trash")
                        }
                        Button(action: { handleShowInfo(chat) }) {
                            Image(systemName: "info")
                        }
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
    
    func handleSelection(_ chat: AgentChat) {
        selection(chat.id)
        dismiss()
    }
    
    func handleDelete(_ chat: AgentChat) {
        Task { await store.delete(chat:chat) }
    }
    
    func handleShowInfo(_ chat: AgentChat) {
        print("not implemented")
    }
}

struct ChatRow: View {
    let chat: AgentChat
    let agent: Agent
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(agent.name)
                .fontWeight(.semibold)
                .lineLimit(1)
            Text(chat.messages.last?.content ?? "Say something...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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
        ChatListView(selection: {_ in})
    }
    .environment(store)
}
