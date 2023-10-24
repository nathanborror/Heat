import SwiftUI
import HeatKit

struct ChatListView: View {
    @Environment(Store.self) private var store
    
    @Binding var selected: AgentChat?
    
    var body: some View {
        List(selection: $selected) {
            ForEach(store.chats) { chat in
                if let agent = store.get(agentID: chat.agentID) {
                    NavigationLink(value: chat) {
                        ChatRow(chat: chat, agent: agent)
                    }
                    .swipeActions {
                        Button(role: .destructive, action: { handleDelete(chat) }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .overlay {
            if store.chats.isEmpty {
                ContentUnavailableView("No Chats", systemImage: "bubble", description: Text("Chats you start will appear here."))
            }
        }
    }
    
    func handleDelete(_ chat: AgentChat) {
        Task { await store.delete(chat:chat) }
    }
}

struct ChatRow: View {
    let chat: AgentChat
    let agent: Agent
    
    var body: some View {
        HStack(spacing: 12) {
            PictureView(picture: agent.picture)
                .frame(width: pictureSize, height: pictureSize)
                .clipShape(Squircle())
            VStack(alignment: .leading) {
                Text(agent.name)
                    .fontWeight(.semibold)
                Text(agent.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    #if os(macOS)
    private let pictureSize: CGFloat = 32
    #else
    private let pictureSize: CGFloat = 54
    #endif
}
