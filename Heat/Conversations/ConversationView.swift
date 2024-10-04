import SwiftUI
import SwiftData
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "App")

struct ConversationView: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    @Binding var selected: String?
    
    @State private var conversationViewModel: ConversationViewModel? = nil
    @State private var showingInspector = false
    
    var body: some View {
        Group {
            if let conversationViewModel {
                MessageList()
                    .environment(conversationViewModel)
            } else {
                VStack {
                    Spacer()
                    ContentUnavailableView {
                        Text("New Conversation")
                    } description: {
                        Text("The beginning of something special.")
                    }
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageField { prompt, images, command in
                handleSubmit(prompt, images: images, command: command)
            }
            .padding(12)
            .background(.background)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    selected = nil
                    conversationViewModel = nil
                } label: {
                    Label("New Conversation", systemImage: "plus")
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
            }
            if selected != nil {
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
            if let selected {
                NavigationStack {
                    ConversationViewInspector(conversationID: selected)
                }
                .inspectorColumnWidth(ideal: 200)
            }
        }
        .onChange(of: selected) { _, newValue in
            if let newValue {
                conversationViewModel = ConversationViewModel(conversationID: newValue)
            } else {
                conversationViewModel = nil
            }
        }
    }
    
    func handleSubmit(_ prompt: String, images: [Data] = [], command: MessageField.Command = .text) {
        Task {
            // Create a new conversation if one isn't already selected
            if conversationViewModel == nil {
                guard let agentID = preferencesProvider.preferences.defaultAgentID else { return }
                let agent = try agentsProvider.get(agentID)
                let conversation = try await conversationsProvider.create(instructions: agent.instructions, toolIDs: agent.toolIDs)
                
                selected = conversation.id
                conversationViewModel = ConversationViewModel(conversationID: conversation.id)
            }
            
            // This should always exist since it was created above
            guard let conversationViewModel else { return }
            
            // Context full of memories
            let context = memories.map { $0.content }
            
            // Try to generate a response
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
