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
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Show message history
                    ForEach(conversationViewModel.messages) { message in
                        MessageView(message: message)
                    }
                    
                    // Show continue button if last message has tool calls
                    if let message = conversationViewModel.messages.last, message.toolCalls != nil {
                        Button(action: { try? conversationViewModel.processToolCalls(message: message) }) {
                            Text("Continue")
                        }
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id("bottom")
                }
                .padding(24)
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
        .overlay(alignment: .bottom) {
            if conversationViewModel.messages.isEmpty {
                VStack {
                    Button(action: { handleSuggestion("Latest Apple rumors") }) {
                        Text("Latest Apple rumors")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .padding(.bottom, 64)
            }
        }
    }
    
    func handleSuggestion(_ suggestion: String) {
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        do {
            try conversationViewModel.generate(suggestion)
        } catch let error as KitError {
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
