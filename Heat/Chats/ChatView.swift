import SwiftUI
import HeatKit

struct ChatView: View {
    @Environment(Store.self) private var store
    
    @State var chatID: String?

    @State private var composerText = ""
    @State private var composerState: ChatComposerView.ViewState = .init()
    @State private var generateTask: Task<(), Error>? = nil
    @State private var modelID: String = ""
    
    @State private var isShowingInfo = false
    @State private var isShowingHistory = false
    @State private var isShowingSettings = false
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    ScrollViewMarker(id: "scrollViewTop")
                    if let chat = chat {
                        ChatHistoryView(chat: chat, messages: messages)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.agents) { agent in
                                AgentTile(
                                    agent: agent,
                                    height: geo.size.width/heightDivisor,
                                    selection: handleAgentSelection
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    ScrollViewMarker(id: "scrollViewBottom")
                }
                .onChange(of: chat?.messages) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onChange(of: chat) { _, newValue in
                    modelID = chat?.modelID ?? modelID
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onChange(of: store.models) { oldValue, newValue in
                    guard oldValue.isEmpty else { return }
                    guard modelID.isEmpty else { return }
                    guard let model = store.getDefaultModel() else { return }
                    modelID = model.id
                }
                .onAppear{
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
            }
        }
        #if os(macOS)
        .navigationTitle(agent?.name ?? "New Chat")
        .navigationSubtitle(model?.name ?? "Choose Model")
        .background(.background)
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ChatComposerView(
                text: $composerText,
                state: composerState,
                submit: handleSubmit,
                stop: handleStop
            )
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbar {
            #if os(macOS)
            Button(action: { isShowingInfo.toggle() }) {
                Label("Pick Model", systemImage: "cube")
            }
            Button(action: { isShowingSettings.toggle() }) {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            Button(action: { isShowingHistory.toggle() }) {
                Label("History", systemImage: "archivebox")
            }
            Button(action: handleNewChat) {
                Label("New Chat", systemImage: "plus")
            }.disabled(chatID == nil)
            #else
            ToolbarItem(placement: .principal) {
                Button(action: { isShowingInfo.toggle() }) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(agent?.name ?? "New Chat")
                            .font(.headline)
                            .tint(.primary)
                        Text(model?.name ?? "Choose Model")
                            .font(.footnote)
                            .tint(model == nil ? .accentColor : .secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: { isShowingHistory.toggle() }) {
                        Label("History", systemImage: "archivebox")
                    }
                    Button(action: { isShowingSettings.toggle() }) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
            ToolbarItem {
                Button(action: handleNewChat) {
                    Label("New Chat", systemImage: "plus")
                }.disabled(chatID == nil)
            }
            #endif
        }
        .sheet(isPresented: $isShowingInfo) {
            NavigationStack {
                ChatInfoView(chatID: chatID, modelID: $modelID)
            }.environment(store)
        }
        .sheet(isPresented: $isShowingHistory) {
            NavigationStack {
                ChatListView(selection: $chatID)
            }.environment(store)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                PreferencesView()
            }.environment(store)
        }
    }
    
    var agent: Agent? {
        guard let chatID = chatID else { return nil }
        guard let chat = store.get(chatID: chatID) else { return nil }
        return store.get(agentID: chat.agentID)
    }
    
    var chat: AgentChat? {
        guard let chatID = chatID else { return nil }
        return store.get(chatID: chatID)
    }
    
    var model: Model? {
        return store.get(modelID: modelID)
    }
    
    var messages: [Message] {
        guard let chat = chat else { return [] }
        return chat.messages.filter { $0.kind != .instruction }
    }
    
    var scrollToPosition: String {
        if chatID != nil {
            "scrollViewBottom"
        } else {
            "scrollViewTop"
        }
    }
    
    func handleNewChat() {
        chatID = nil
        composerState.change(.resting)
    }
    
    func handleSubmit(_ text: String) {
        guard isModelPicked() else { return }
        
        generateTask = Task {
            if chatID == nil { await handleCreateChat(agent: .assistant) }
            guard let chat = chat else { return }
            
            let message = store.createMessage(role: .user, content: text)
            try await ChatManager(store: store, chat: chat)
                .inject(message: message)
                .generateStream()
        }
    }
    
    func handleStop() {
        generateTask?.cancel()
    }
    
    func handleAgentSelection(_ agent: Agent) {
        guard isModelPicked() else { return }
        
        generateTask = Task {
            await handleCreateChat(agent: agent)
            guard let chat = chat else { return }
            
            DispatchQueue.main.async {
                composerState.change(.focused)
            }
            
            let message = store.createMessage(kind: .instruction, role: .user, content: agent.prompt)
            try await ChatManager(store: store, chat: chat)
                .inject(message: message)
                .generateStream()
        }
    }
    
    func handleCreateChat(agent: Agent) async {
        let chat = store.createChat(modelID: modelID, agentID: agent.id)
        await store.upsert(chat: chat)
        self.chatID = chat.id
    }
    
    func isModelPicked() -> Bool {
        if modelID.isEmpty {
            isShowingInfo = true
            return false
        }
        return true
    }
    
    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let heightDivisor: CGFloat = 3.5
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let heightDivisor: CGFloat = 2.75
    #endif
}

struct ChatHistoryView: View {
    let chat: AgentChat
    let messages: [Message]
    
    var body: some View {
        LazyVStack {
            if let system = chat.system {
                Text(system)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            }
            
            ForEach(messages) { message in
                ChatMessageContainerView(message: message)
            }
            if chat.state == .processing {
                ChatTypingIndicatorView(.leading)
            }
        }
        .padding()
    }
}

struct ScrollViewMarker: View {
    let id: String
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .id(id)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
    .environment(Store.preview)
}
