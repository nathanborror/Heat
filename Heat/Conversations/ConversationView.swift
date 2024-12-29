import SwiftUI
import SwiftData
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "App")

struct ConversationView: View {
    @Environment(AppState.self) var state
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
                MessageListScrollView {
                    AssistantPicker()
                }
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageField { prompt, images, command in
                handleSubmit(prompt, images: images, command: command)
            } agent: { agent in
                handleSubmit(agent: agent)
            }
            .padding(12)
            .background(.background)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    selected = nil
                    conversationViewModel = nil
                } label: {
                    Label("New Conversation", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

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
                .disabled(selected == nil)
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
                guard let agentID = state.preferencesProvider.preferences.defaultAssistantID else { return }
                let agent = try state.agentsProvider.get(agentID)
                let conversation = try await state.conversationsProvider.create(instructions: agent.instructions, toolIDs: agent.toolIDs)

                selected = conversation.id
                conversationViewModel = ConversationViewModel(conversationID: conversation.id)
            }

            // This should always exist since it was created above
            guard let conversationViewModel else { return }

            // Context full of memories
            let context = ["MEMORIES": memories.map { $0.content }.joined(separator: "\n")]

            // Try to generate a response
            do {
                switch command {
                case .text:
                    try await conversationViewModel.generate(chat: prompt, images: images, context: context)
                case .imagine:
                    try await conversationViewModel.generate(image: prompt)
                }
            } catch {
                print(error)
            }
        }
    }

    func handleSubmit(agent: Agent) {
        Task {
            // Create a new conversation if one isn't already selected
            if conversationViewModel == nil {
                guard let agentID = state.preferencesProvider.preferences.defaultAssistantID else { return }
                let agent = try state.agentsProvider.get(agentID)
                let conversation = try await state.conversationsProvider.create(instructions: agent.instructions, toolIDs: agent.toolIDs)

                selected = conversation.id
                conversationViewModel = ConversationViewModel(conversationID: conversation.id)
            }
            guard let conversationViewModel else { return }
            do {
                try await conversationViewModel.generate(chat: agent.instructions, context: agent.context, agentID: agent.id)
            } catch {
                print(error)
            }
        }
    }
}
