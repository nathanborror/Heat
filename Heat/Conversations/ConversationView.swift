import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var isShowingError = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    
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
                                SuggestionView(suggestion: suggestion) { suggestion in
                                    Task { try await handleSuggestion(suggestion) }
                                }
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
//        .alert(isPresented: $isShowingError, error: conversationViewModel.error) { _ in
//            Button("Dismiss", role: .cancel) {
//                isShowingError = false
//                conversationViewModel.error = nil
//            }
//        } message: {
//            Text($0.recoverySuggestion)
//        }
    }
    
    func handleSuggestion(_ suggestion: String) async throws {
        if conversationViewModel.conversationID == nil {
            try await conversationViewModel.newConversation()
        }
        do {
            try conversationViewModel.generate(chat: suggestion)
        } catch {
            conversationViewModel.error = error
        }
    }
}
