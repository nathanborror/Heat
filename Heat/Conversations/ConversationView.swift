import SwiftUI
import HeatKit

struct ConversationView: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) private var viewModel
    
    @State private var isShowingError = false
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 4) {
                    
                    // Messages
                    ForEach(viewModel.humanVisibleMessages) { message in
                        MessageBubble(message: message)
                    }
                    
                    // Typing indicator
                    if viewModel.conversation?.state == .processing {
                        TypingIndicator(.leading)
                    }
                    
                    ScrollMarker(id: "bottom")
                }
                .padding(.horizontal)
                .padding(.top, 64)
                .onChange(of: viewModel.conversationID) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: viewModel.conversation) { _, _ in
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
                .environment(viewModel)
                .padding()
                .background(.background)
        }
        .alert(isPresented: $isShowingError, error: viewModel.error) { _ in
            Button("Dismiss", role: .cancel) {
                isShowingError = false
                viewModel.error = nil
            }
        } message: {
            Text($0.recoverySuggestion)
        }
        .onChange(of: viewModel.error) { _, newValue in
            guard newValue != nil else { return }
            isShowingError = true
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
    let viewModel = ConversationViewModel(store: store)
    viewModel.conversationID = store.conversations.first?.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
