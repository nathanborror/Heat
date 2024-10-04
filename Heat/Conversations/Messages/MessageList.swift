import SwiftUI
import SwiftData
import SharedKit
import HeatKit

struct MessageList: View {
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    var body: some View {
        ScrollViewReader { proxy in
            MessageListScrollView {
                // Show message run history
                ForEach(conversationViewModel.runs) { run in
                    RunView(run: run)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
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
                            SuggestionView(suggestion: suggestion) { handleSubmit($0) }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 24)
                .id("bottom")
            }
            .onAppear {
                proxy.scrollTo("bottom")
            }
            .onChange(of: conversationViewModel.streamingTokens) { _, _ in
                proxy.scrollTo("bottom")
            }
        }
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }
    
    func handleSubmit(_ prompt: String) {
        Task {
            do {
                let context = memories.map { $0.content }
                try conversationViewModel.generate(chat: prompt, context: context)
            } catch {
                conversationViewModel.error = error
            }
        }
    }
}

/// Wrapper for scrolling message views. Using a `List` has much better scrolling performance on macOS.
/// On iOS the `List` studders when text is streaming and the scroll position is updated.
struct MessageListScrollView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        #if os(macOS)
        List {
            content()
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
        }
        #endif
    }
}
