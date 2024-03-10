import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var isShowingError = false
    
    var body: some View {
        ScrollView {
            
            // Making this a LazyVStack causes an undesirable animation behavior that appears to be influenced by the
            // TypingIndicator animation, VStack solves this until I can debug.
            VStack(spacing: 16) {
                
                // Pushes the initial conversation to the bottom (desirable) and also fixes a bug with tap targets not
                // lining up properly when relying on defaultScrollAnchor(.bottom).
                HStack {
                    Image("Icon")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .padding(6)
                        .background(.primary)
                        .clipShape(Squircle())
                        .opacity(hasHistory ? 0 : 1)
                        
                }
                .containerRelativeFrame(.vertical)
                
                // Show message history
                ForEach(conversationViewModel.messagesVisible) { message in
                    switch message.role {
                    case .user, .assistant:
                        MessageView(message: message)
                    case .tool:
                        MessageTool(message: message)
                    case .system:
                        MessageSystem(message: message)
                    }
                }
                
                // Assistant typing indicator when processing
                if conversationViewModel.conversation?.state == .processing {
                    TypingIndicator()
                }
                
                // Suggestions typing indicator when suggesting
                if conversationViewModel.conversation?.state == .suggesting {
                    TypingIndicator(foregroundColor: .accentColor)
                }
                
                // Show suggestions when they are available
                if !conversationViewModel.suggestions.isEmpty {
                    SuggestionList(suggestions: conversationViewModel.suggestions) { suggestion in
                        SuggestionView(suggestion: suggestion, action: { handleSuggestion(.init($0)) })
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(.background)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ConversationInput()
                .environment(conversationViewModel)
                .padding(12)
                .background(.background)
        }
        .alert(isPresented: $isShowingError, error: conversationViewModel.error) { _ in
            Button("Dismiss", role: .cancel) {
                isShowingError = false
                conversationViewModel.error = nil
            }
        } message: {
            Text($0.recoverySuggestion)
        }
        .onChange(of: conversationViewModel.error) { _, newValue in
            guard newValue != nil else { return }
            isShowingError = true
        }
    }
    
    func handleSuggestion(_ suggestion: String) {
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        do {
            try conversationViewModel.generate(suggestion)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
    }
    
    private var hasHistory: Bool {
        !conversationViewModel.messagesVisible.isEmpty
    }
}

#Preview("New Conversation") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: Store.preview)
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}

#Preview("Active Conversation") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: Store.preview)
    viewModel.conversationID = store.conversations.first?.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
