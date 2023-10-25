import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ContentView", category: "Heat")

struct ContentView: View {
    @Environment(Store.self) private var store
    @Environment(Router.self) private var router
    
    @State var selectedChat: AgentChat? = nil
    @State var isShowingAgents = false
    @State var isShowingSettings = false
    @State var preferences: Preferences = .empty
    
    var body: some View {
        NavigationSplitView {
            ChatListView(selected: $selectedChat)
                #if os(macOS)
                .listStyle(.sidebar)
                #else
                .listStyle(.plain)
                #endif
                .navigationTitle("Chats")
                .navigationSplitViewColumnWidth(220)
                .toolbar {
                    Button(action: { router.present(.agentList) }) {
                        Image(systemName: "plus")
                    }
                    Button(action: { router.present(.preferences) }) {
                        Image(systemName: "ellipsis")
                    }
                }
        } detail: {
            if let chat = selectedChat {
                ChatView(chatID: chat.id)
                    .navigationTitle(store.get(agentID: chat.agentID)?.name ?? "Unknown")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .background(.background)
            }
        }
        .onChange(of: store.preferences) { _, newValue in
            preferences = newValue
        }
    }
}

#Preview {
    ContentView()
        .environment(Store.shared)
}
