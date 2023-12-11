import SwiftUI
import HeatKit

struct ConversationView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel

    @State private var composerText = ""
    @State private var composerState: ConversationComposerView.ViewState = .init()
    
    @State private var isShowingInfo = false
    @State private var isShowingAgentForm = false
    @State private var isShowingHistory = false
    @State private var isShowingSettings = false
    @State private var isShowingError = false
    
    @State private var storeError: StoreError? = nil
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    ConversationScrollViewMarker(id: "scrollViewTop")
                    if viewModel.conversationID != nil {
                        ChatHistoryView()
                    } else {
                        ChatAgentList(size: geo.size, selection: handleSelect)
                    }
                    ConversationScrollViewMarker(id: "scrollViewBottom")
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.conversationID) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onChange(of: viewModel.conversation) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onAppear {
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
            }
        }
        #if os(macOS)
        .navigationTitle(viewModel.agent?.name ?? "New Chat")
        .navigationSubtitle(viewModel.model?.name ?? "Choose Model")
        .background(.background)
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ConversationComposerView(
                text: $composerText,
                state: composerState,
                submit: viewModel.generateResponse,
                stop: viewModel.cancel
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
            Button(action: handleNewConversation) {
                Label("New Chat", systemImage: "plus")
            }
            .disabled(viewModel.conversationID == nil)
            #else
            ToolbarItem(placement: .principal) {
                Button(action: { isShowingInfo.toggle() }) {
                    Text("Conversation")
                        .font(.headline)
                        .tint(.primary)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: { isShowingAgentForm.toggle() }) {
                        Label("New Agent", systemImage: "plus")
                    }
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
                Button(action: handleNewConversation) {
                    Label("New Conversation", systemImage: "plus")
                }.disabled(viewModel.conversationID == nil)
            }
            #endif
        }
        .sheet(isPresented: $isShowingInfo) {
            NavigationStack {
                ConversationInfoView()
            }
            .environment(store)
            .environment(viewModel)
        }
        .sheet(isPresented: $isShowingAgentForm) {
            NavigationStack {
                AgentForm(agent: .empty)
            }
            .environment(store)
        }
        .sheet(isPresented: $isShowingHistory) {
            NavigationStack {
                ConversationListView(selection: handleSelect)
            }
            .environment(store)
            .environment(viewModel)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                PreferencesView()
            }
            .environment(store)
        }
        .alert(isPresented: $isShowingError, error: storeError) { _ in
            Button("Dismiss") {
                self.isShowingError = false
                self.storeError = nil
            }
        } message: { _ in
            Text("Check that your Ollama server is running on port 8080 and make sure you've pulled some models.")
        }
    }
    
    var scrollToPosition: String {
        if viewModel.conversationID != nil {
            "scrollViewBottom"
        } else {
            "scrollViewTop"
        }
    }
    
    func handleNewConversation() {
        viewModel.conversationID = nil
        composerState.change(.resting)
    }
    
    func handleSelect(agent: Agent) {
        Task {
            DispatchQueue.main.async {
                composerState.change(.focused)
            }
            
            let manager = try await ConversationManager(store: store)
                .initialize(agentID: agent.id) { conversationID in
                    viewModel.conversationID = conversationID
                }
                .generateStream()
            
            if store.preferences.isSuggesting {
                try await manager
                    .generateSuggestions()
            }
        }
    }
    
    func handleSelect(conversationID: String) {
        viewModel.conversationID = conversationID
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
    private let heightDivisor: CGFloat = 3
    #endif
}

struct ChatHistoryView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel
    
    var body: some View {
        LazyVStack {
            
            // Message list
            ForEach(viewModel.messages) { message in
                ConversationMessageContainerView(message: message)
            }
            
            // Indicators and suggestions
            if let conversation = viewModel.conversation {
                if conversation.state == .processing {
                    ConversationTypingIndicatorView(.leading)
                }
                if conversation.state == .suggesting {
                    ConversationTypingIndicatorView(.trailing)
                }
                if viewModel.suggestions.count > 0 {
                    ConversationSuggestionsView(suggestions: viewModel.suggestions) { suggestion in
                        viewModel.generateResponse(suggestion)
                    }
                }
            }
        }
        .padding()
    }
}

struct ConversationSuggestionsView: View {
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

struct ConversationScrollViewMarker: View {
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
    let viewModel = ConversationViewModel(store: store)
    
    //let conversation = store.conversations.first!
    //viewModel.conversationID = conversation.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
