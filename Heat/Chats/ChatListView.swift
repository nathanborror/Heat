import SwiftUI
import HeatKit

struct ChatListView: View {
    @Environment(Store.self) private var store
    
    @State var router: MainRouter
    
    var body: some View {
        RoutingView(router: router) {
            List {
                ForEach(store.chats) { chat in
                    if let agent = store.get(agentID: chat.agentID) {
                        Button(action: { router.presentChat(chat.id) }) {
                            ChatRow(chat: chat, agent: agent)
                        }
                        .tint(.primary)
                        .swipeActions {
                            Button(role: .destructive, action: { handleDelete(chat) }) {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .overlay {
                if store.chats.isEmpty {
                    ContentUnavailableView("No Chats", systemImage: "bubble", description: Text("Chats you start will appear here."))
                }
            }
            .toolbar {
                Button(action: { router.presentAgents() }) {
                    Image(systemName: "plus")
                }
                Button(action: { router.presentPreferences() }) {
                    Image(systemName: "ellipsis")
                }
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
            Spacer()
            Image.chevron
        }
    }
    
    #if os(macOS)
    private let pictureSize: CGFloat = 32
    #else
    private let pictureSize: CGFloat = 54
    #endif
}
