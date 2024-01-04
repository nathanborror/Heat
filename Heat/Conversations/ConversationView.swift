import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel

    @State private var messageInputText = ""
    @State private var messageInputState: MessageInputViewState = .init()
    
    @State private var sheet: Sheet? = nil
    
    @State private var isShowingError = false
    @State private var error: AppError? = nil
    
    enum Sheet: String, Identifiable {
        case history, preferences, agentForm
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
        .navigationTitle(viewModel.title)
        .background(.background)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageInput(
                text: $messageInputText,
                submit: handleGenerateResponse,
                stop: viewModel.cancel
            )
            .environment(messageInputState)
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbar {
            #if os(macOS)
            Button(action: { sheet = .preferences }) {
                Label("Preferences", systemImage: "slider.horizontal.3")
            }
            Button(action: { sheet = .history }) {
                Label("History", systemImage: "archivebox")
            }
            Button(action: handleClear) {
                Label("New Chat", systemImage: "plus")
            }
            .disabled(viewModel.conversationID == nil)
            #else
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: { sheet = .agentForm }) {
                        Label("New Agent", systemImage: "plus")
                    }
                    Button(action: { sheet = .history }) {
                        Label("History", systemImage: "archivebox")
                    }
                    Button(action: { sheet = .preferences }) {
                        Label("Preferences", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
            ToolbarItem {
                Button(action: handleClear) {
                    Label("New Conversation", systemImage: "plus")
                }.disabled(viewModel.conversationID == nil)
            }
            #endif
        }
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case .history:
                    ConversationListView(selection: handleSelect)
                case .preferences:
                    PreferencesForm(preferences: store.preferences)
                case .agentForm:
                    AgentForm(agent: .empty)
                }
            }
            .environment(store)
            .environment(viewModel)
        }
        .alert(isPresented: $isShowingError, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                isShowingError = false
                error = nil
            }
            Button("Preferences") {
                sheet = .preferences
                isShowingError = false
                error = nil
            }
        } message: { error in
            Text(error.explanation)
        }
    }
    
    var scrollToPosition: String {
        if viewModel.conversationID != nil {
            "scrollViewBottom"
        } else {
            "scrollViewTop"
        }
    }
    
    func handleClear() {
        viewModel.conversationID = nil
        messageInputState.change(.resting)
    }
    
    func handleSelect(agent: Agent) {
        guard handleReadinessCheck() else { return }
        
        let conversation = Conversation(messages: agent.messages)
        store.upsert(conversation: conversation)

        // Switch conversation
        handleSelect(conversationID: conversation.id)
        
        // Genrate an introduction
        viewModel.generateResponse()
        
        // Show keyboard
        messageInputState.change(.focused)
    }
    
    func handleSelect(conversationID: String) {
        viewModel.conversationID = conversationID
    }
    
    func handleGenerateResponse(content: String) {
        guard handleReadinessCheck() else { return }
        if viewModel.conversationID == nil {
            let conversation = Conversation(messages: Agent.assistant.messages)
            store.upsert(conversation: conversation)
            handleSelect(conversationID: conversation.id)
        }
        viewModel.generateResponse(content: content)
    }
    
    func handleReadinessCheck() -> Bool {
        
        // Ensure service can be used
        switch store.preferences.service {
        case .ollama:
            guard store.preferences.host != nil else {
                error = .missingHost
                isShowingError = true
                return false
            }
        case .openai:
            guard store.preferences.token != nil else {
                error = .missingToken
                isShowingError = true
                return false
            }
        case .mistral:
            guard store.preferences.token != nil else {
                error = .missingToken
                isShowingError = true
                return false
            }
        }
        
        // Ensure model is selected
        guard store.preferences.model != nil else {
            error = .missingModel
            isShowingError = true
            return false
        }
        
        // Good to go
        return true
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
            ForEach(viewModel.messages) { message in
                MessageBubble(message: message)
            }
            if let conversation = viewModel.conversation {
                if conversation.state == .processing {
                    TypingIndicator(.leading)
                }
            }
        }
        .padding()
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

// MARK: - Previews

#Preview("Agent Picker") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: store)
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}

#Preview("Conversation") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: store)
    
    let conversation = store.conversations.first!
    viewModel.conversationID = conversation.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
