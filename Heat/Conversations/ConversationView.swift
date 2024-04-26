import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var isShowingError = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Image("IconLight")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .padding(4)
                            .background(.primary.opacity(0.1))
                            .clipShape(Squircle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 64)
                    
                    // Show message history
                    ForEach(conversationViewModel.messages) { message in
                        MessageView(message: message)
                    }
                    
                    VStack(spacing: 0) {
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
                            .padding(.vertical, 8)
                        }
                    }
                    .id("bottom")
                }
                .padding(.horizontal, 24)
            }
            .task(id: conversationViewModel.conversation) {
                proxy.scrollTo("bottom")
            }
            .task(id: conversationViewModel.error) {
                isShowingError = conversationViewModel.error != nil
            }
        }
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
}

#Preview("New") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: Store.preview)
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}

#Preview("Active") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: Store.preview)
    viewModel.conversationID = Conversation.preview1.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}

#Preview("Tool Use") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: Store.preview)
    viewModel.conversationID = Conversation.preview2.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
