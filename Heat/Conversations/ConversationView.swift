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
            ScrollViewReader { proxy in
                LazyVStack(spacing: 11) {
                    
                    // Messages
                    ForEach(conversationViewModel.messagesVisible) { message in
                        MessageView(message: message)
                    }
                    
                    // Typing indicator
                    if conversationViewModel.conversation?.state == .processing {
                        TypingIndicator()
                    }
                    
                    // Suggestions
                    if conversationViewModel.conversation?.state == .suggesting {
                        TypingIndicator(foregroundColor: .accentColor)
                    }
                    SuggestionList(suggestions: conversationViewModel.suggestions) { suggestion in
                        SuggestionView(suggestion: suggestion, action: { handleSuggestion(.init($0)) })
                    }
                    .padding(.top, 8)
                    
                    ScrollMarker(id: "bottom")
                }
                .padding(.horizontal, 24)
                #if os(macOS)
                .padding(.top, 32)
                #endif
                .onChange(of: conversationViewModel.conversationID) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: conversationViewModel.conversation?.modified) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .background(.background)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
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
}

struct ScrollMarker: View {
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
    let viewModel = ConversationViewModel(store: Store.preview)
    viewModel.conversationID = store.conversations.first?.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
