import SwiftUI
import GenKit
import HeatKit

struct ConversationView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel

    @State private var messageInputText = ""
    @State private var messageInputState: MessageInputViewState = .init()
    
    @State private var sheet: Sheet? = nil
    @State private var isShowingServerAlert = false
    @State private var storeError: StoreError? = nil
    
    enum Sheet: String, Identifiable {
        case info, history, preferences, agentForm
        var id: String { rawValue }
    }
    
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
        .navigationTitle("Conversation")
        .navigationSubtitle(viewModel.model?.name ?? "Choose Model")
        .background(.background)
        #else
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageInput(
                text: $messageInputText,
                submit: viewModel.generateResponse,
                stop: viewModel.cancel
            )
            .environment(messageInputState)
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbar {
            #if os(macOS)
            Button(action: { sheet = .preferences }) {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            Button(action: { sheet = .history }) {
                Label("History", systemImage: "archivebox")
            }
            Button(action: handleNewConversation) {
                Label("New Chat", systemImage: "plus")
            }
            .disabled(viewModel.conversationID == nil)
            #else
            ToolbarItem(placement: .principal) {
                Button(action: { sheet = .info }) {
                    Text("Conversation")
                        .font(.headline)
                        .tint(.primary)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: { sheet = .agentForm }) {
                        Label("New Agent", systemImage: "plus")
                    }
                    Button(action: { sheet = .history }) {
                        Label("History", systemImage: "archivebox")
                    }
                    Button(action: { sheet = .preferences }) {
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
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .info:
                    ConversationInfoView()
                case .history:
                    ConversationListView(selection: handleSelect)
                case .preferences:
                    PreferencesView()
                case .agentForm:
                    AgentForm(agent: .empty)
                }
            }
            .environment(store)
            .environment(viewModel)
        }
        .alert(isPresented: $isShowingServerAlert, error: storeError) { _ in
            Button("Dismiss") {
                self.isShowingServerAlert = false
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
        messageInputState.change(.resting)
    }
    
    func handleSelect(agent: Agent) {
        guard let model = store.getPreferredModel() else {
            storeError = .missingModel
            isShowingServerAlert = true
            return
        }
        
        let conversation = Conversation(modelID: model.id, messages: agent.messages, state: .processing)
        store.upsert(conversation: conversation)
        
        viewModel.conversationID = conversation.id
        
        Task {
            DispatchQueue.main.async {
                messageInputState.change(.focused)
            }
            
            await MessageManager(messages: conversation.messages)
                .generate(service: OllamaService.shared, model: conversation.modelID)
                .sink {
                    store.upsert(messages: $0, conversationID: conversation.id)
                    store.set(state: .none, conversationID: conversation.id)
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
                MessageBubble(message: message)
            }
            
            // Indicators and suggestions
            if let conversation = viewModel.conversation {
                if conversation.state == .processing {
                    TypingIndicator(.leading)
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
