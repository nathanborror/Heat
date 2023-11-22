import SwiftUI
import HeatKit

struct ChatView: View {
    @Environment(Store.self) private var store
    @Environment(ChatViewModel.self) private var chatViewModel

    @State private var composerText = ""
    @State private var composerState: ChatComposerView.ViewState = .init()
    
    @State private var isShowingInfo = false
    @State private var isShowingHistory = false
    @State private var isShowingSettings = false
    @State private var isShowingError = false
    
    @State private var storeError: StoreError? = nil
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    ChatScrollViewMarker(id: "scrollViewTop")
                    if chatViewModel.chatID != nil {
                        ChatHistoryView()
                    } else {
                        ChatAgentList(size: geo.size, selection: handleAgentSelection)
                    }
                    ChatScrollViewMarker(id: "scrollViewBottom")
                }
                .scrollIndicators(.hidden)
                .onChange(of: chatViewModel.chatID) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onChange(of: chatViewModel.chat) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onAppear {
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
            }
        }
        #if os(macOS)
        .navigationTitle(chatViewModel.agent?.name ?? "New Chat")
        .navigationSubtitle(chatViewModel.model?.name ?? "Choose Model")
        .background(.background)
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ChatComposerView(
                text: $composerText,
                state: composerState,
                submit: chatViewModel.generateResponse,
                stop: chatViewModel.cancel
            )
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbar {
            #if os(macOS)
            Button(action: { isShowingSettings.toggle() }) {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            Button(action: { isShowingHistory.toggle() }) {
                Label("History", systemImage: "archivebox")
            }
            Button(action: handleNewChat) {
                Label("New Chat", systemImage: "plus")
            }
            .disabled(chatViewModel.chatID == nil)
            .alert(isPresented: $isShowingError, error: storeError) { _ in
                Button("Dismiss") {
                    self.isShowingError = false
                    self.storeError = nil
                }
            } message: { _ in
                Text("Check that your Ollama server is running on port 8080 and make sure you've pulled some models.")
            }
            #else
            ToolbarItem(placement: .principal) {
                Button(action: { isShowingInfo.toggle() }) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(chatViewModel.agent?.name ?? "New Chat")
                            .font(.headline)
                            .tint(.primary)
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
                }.disabled(chatViewModel.chatID == nil)
            }
            #endif
        }
        .sheet(isPresented: $isShowingInfo) {
            NavigationStack {
                ChatInfoView()
            }
            .environment(store)
            .environment(chatViewModel)
        }
        .sheet(isPresented: $isShowingHistory) {
            NavigationStack {
                ChatListView(selection: handleSelectChat)
            }
            .environment(store)
            .environment(chatViewModel)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                PreferencesView()
            }
            .environment(store)
        }
    }
    
    var scrollToPosition: String {
        if chatViewModel.chatID != nil {
            "scrollViewBottom"
        } else {
            "scrollViewTop"
        }
    }
    
    func handleNewChat() {
        chatViewModel.chatID = nil
        composerState.change(.resting)
    }
    
    func handleAgentSelection(_ agent: Agent) {
        Task {
            await handleCreateChat(agent: agent)
            guard let chat = chatViewModel.chat else { return }
            
            DispatchQueue.main.async {
                composerState.change(.focused)
            }
            
            let message = store.createMessage(kind: .instruction, role: .user, content: agent.prompt)
            let manager = try await ChatManager(store: store, chat: chat)
                .append(message)
                .generateStream()
            if store.preferences.isSuggesting {
                try await manager
                    .generateSuggestions()
            }
        }
    }
    
    func handleCreateChat(agent: Agent) async {
        do {
            let chat = try store.createChat(agentID: agent.id)
            await store.upsert(chat: chat)
            chatViewModel.chatID = chat.id
        } catch let error as StoreError {
            isShowingError = true
            self.storeError = error
        } catch {
            print(error)
        }
    }
    
    func handleSelectChat(_ chatID: String) {
        chatViewModel.chatID = chatID
    }
}

struct ChatAgentList: View {
    @Environment(Store.self) private var store
    
    let size: CGSize
    let selection: (Agent) -> Void
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.agents) { agent in
                AgentTile(
                    agent: agent,
                    height: size.width/heightDivisor,
                    selection: selection
                )
            }
        }
        .padding(.horizontal)
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
    @Environment(Store.self) private var store
    @Environment(ChatViewModel.self) private var chatViewModel
    
    var body: some View {
        LazyVStack {
            
            // System message
            if store.preferences.isDebug {
                if let chat = chatViewModel.chat, let system = chat.system {
                    Text(system)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical)
                }
            }
            
            // Message list
            ForEach(chatViewModel.messages) { message in
                ChatMessageContainerView(message: message)
            }
            
            // Indicators and suggestions
            if let chat = chatViewModel.chat {
                if chat.state == .processing {
                    ChatTypingIndicatorView(.leading)
                }
                if chat.state == .suggesting {
                    ChatTypingIndicatorView(.trailing)
                }
                if chatViewModel.suggestions.count > 0 {
                    ChatSuggestionsView(suggestions: chatViewModel.suggestions) { suggestion in
                        chatViewModel.generateResponse(suggestion)
                    }
                }
            }
        }
        .padding()
    }
}

struct ChatSuggestionsView: View {
    let suggestions: [String]
    let action: (String) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(suggestions.indices, id: \.self) { index in
                HStack {
                    Spacer()
                    Button(action: { action(suggestions[index]) }) {
                        Text(suggestions[index])
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.tint.opacity(0.1))
                    .foregroundStyle(.tint)
                    .clipShape(.rect(cornerRadius: 20))
                }
            }
        }
    }
}

struct ChatScrollViewMarker: View {
    let id: String
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .id(id)
    }
}

#Preview {
    let store = Store.preview
    let chatViewModel = ChatViewModel(store: store)
    
    let chat = store.chats.first!
    chatViewModel.chatID = chat.id
    
    return NavigationStack {
        ChatView()
    }
    .environment(store)
    .environment(chatViewModel)
}
