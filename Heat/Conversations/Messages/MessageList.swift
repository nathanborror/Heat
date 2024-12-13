import SwiftUI
import SwiftData
import SharedKit
import HeatKit

struct MessageList: View {
    @Environment(AppState.self) var state
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]

    var body: some View {
        ScrollViewReader { proxy in
            MessageListScrollView {

                // Show message run history
                ForEach(conversationViewModel.runs) { run in
                    RunView(run)
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
                    }
                }
                .id("bottom")
            }
            .onChange(of: state.messagesProvider.updated) { _, _ in
                proxy.scrollTo("bottom")
            }
            .onAppear {
                proxy.scrollTo("bottom")
            }
            .onOpenURL { url in
                if let suggestion = url.queryParameters["suggestion"] {
                    handleSubmit(suggestion.replacingOccurrences(of: "+", with: " "))
                }
                proxy.scrollTo("bottom")
            }
        }
    }

    func handleSubmit(_ prompt: String) {
        Task {
            do {
                let context = ["MEMORIES": memories.map { $0.content }.joined(separator: "\n")]
                try await conversationViewModel.generate(chat: prompt, context: context)
            } catch {
                print(error)
//                conversationViewModel.error = error
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
                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
        }
        .listStyle(.plain)
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.horizontal, 12)
        }
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        #endif
    }
}
