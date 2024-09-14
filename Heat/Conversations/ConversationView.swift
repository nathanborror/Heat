import SwiftUI
import SwiftData
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    @State private var showingInspector = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
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
                        .padding(.horizontal, 24)
                        .id("bottom")
                    }
                    .frame(maxWidth: 800, alignment: .center)
                    .padding(.top, 24)
                    Spacer(minLength: 0)
                }
            }
            .background(.background)
            .onChange(of: conversationViewModel.streamingTokens) { _, _ in
                proxy.scrollTo("bottom")
            }
        }
        .defaultScrollAnchor(.bottom)
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageInput()
                .environment(conversationViewModel)
                .padding(12)
                .background(.background)
        }
        .toolbar {
            if conversationViewModel.conversationID != nil {
                ToolbarItem {
                    Button {
                        showingInspector.toggle()
                    } label: {
                        Label("Info", systemImage: "sidebar.right")
                    }
                    .keyboardShortcut("0", modifiers: [.command, .option])
                }
            }
        }
        .inspector(isPresented: $showingInspector) {
            if let conversation = conversationViewModel.conversation {
                NavigationStack {
                    ConversationInspector(conversationID: conversation.id, instructions: conversation.instructions)
                }
                .inspectorColumnWidth(ideal: 200)
            }
        }
        .overlay {
            if conversationViewModel.conversationID == nil {
                ContentUnavailableView {
                    Label("No conversation", systemImage: "message")
                } description: {
                    Text("Your conversation will show here after you send your first message.")
                }
            }
        }
    }
    
    func handleSuggestion(_ suggestion: String) async throws {
        do {
            try conversationViewModel.generate(chat: suggestion, context: memories.map { $0.content })
        } catch {
            conversationViewModel.error = error
        }
    }
}
