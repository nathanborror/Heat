import SwiftUI
import SwiftData
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "App")

struct ConversationView: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.debug) private var debug
    
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    @State private var showingInspector = false
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
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
            .listStyle(.plain)
            .onChange(of: conversationViewModel.streamingTokens) { _, _ in
                proxy.scrollTo("bottom")
            }
        }
        .scrollClipDisabled()
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageInput { prompt, images, command in
                handleSubmit(prompt, images: images, command: command)
            }
            .padding(12)
            .background(.background)
        }
        .toolbar {
            if conversationViewModel.conversationID != nil {
                ToolbarItem {
                    Button {
                        showingInspector.toggle()
                    } label: {
                        #if os(macOS)
                        Label("Info", systemImage: "sidebar.right")
                        #else
                        Label("Info", systemImage: "info")
                        #endif
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
    }
    
    func handleSubmit(_ prompt: String, images: [Data] = [], command: MessageInput.Command = .text) {
        Task {
            let context = memories.map { $0.content }
            do {
                switch command {
                case .text:
                    try conversationViewModel.generate(chat: prompt, context: context)
                case .vision:
                    try conversationViewModel.generate(chat: prompt, images: images, context: context)
                case .imagine:
                    try conversationViewModel.generate(image: prompt)
                }
            } catch {
                conversationViewModel.error = error
            }
        }
    }
}
