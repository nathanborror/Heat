import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ContentView", category: "Heat")

struct ContentView: View {
    @Environment(Store.self) private var store
    
    @State var selectedChat: AgentChat? = nil
    @State var isShowingAgents = false
    @State var isShowingSettings = false
    @State var settings: Settings = .empty
    
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
                    Button(action: { isShowingAgents.toggle() }) {
                        Image(systemName: "plus")
                    }
                    Button(action: { isShowingSettings.toggle() }) {
                        Image(systemName: "ellipsis")
                    }
                }
        } detail: {
            if let chat = selectedChat {
                ChatView(chatID: chat.id)
                    .navigationTitle(store.get(agentID: chat.agentID)?.name ?? "Unknown")
            }
        }
        .sheet(isPresented: $isShowingAgents) {
            NavigationStack {
                AgentListView()
                    .navigationTitle("Pick Agent")
                    .toolbar {
                        Button("Done", action: { isShowingAgents.toggle() })
                    }
            }
            .environment(store)
            .frame(idealWidth: 400, idealHeight: 500)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView(settings: $settings)
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem {
                            Button("Done", action: handleSaveSettings)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel", action: { isShowingSettings.toggle() })
                        }
                    }
            }
            .frame(idealWidth: 400, idealHeight: 500)
        }
        .onChange(of: store.settings) { _, newValue in
            settings = newValue
        }
    }
    
    func handleSaveSettings() {
        Task {
            await store.upsert(settings: settings)
            try await store.saveAll()
        }
        isShowingSettings.toggle()
    }
}

#Preview {
    ContentView()
        .environment(Store.shared)
}
