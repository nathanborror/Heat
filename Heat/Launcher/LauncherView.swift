#if os(macOS)
import SwiftUI
import SwiftData
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "LauncherView", category: "App")

struct LauncherView: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var content = ""
    @State private var isShowingContent = false
    @State private var isShowingError = false
    
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    @Binding var selected: String?
    
    @State private var conversationViewModel: ConversationViewModel? = nil
    
    let delay: TimeInterval = 2.0
    
    var body: some View {
        LauncherPanel(isShowingContent: $isShowingContent) {
            HStack {
                Image("IconDark")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .opacity(0.1)
                TextField("Lets go", text: $content, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.title)
                    .onSubmit {
                        handleSubmit()
                    }
            }
            .padding()
        } content: {
            if let conversationViewModel {
                MessageList()
                    .environment(conversationViewModel)
            }
        }
        .task {
            handleInit()
        }
    }
    
    @MainActor func handleInit() {
        guard conversationViewModel != nil else { return }
        isShowingContent = true
    }
    
    func handleSubmit() {
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
                try conversationViewModel.generate(chat: content, context: context)
            } catch {
                conversationViewModel.error = error
            }
            
            content = ""
            isShowingContent = true
        }
    }
}

struct LauncherPanel<Toolbar: View, Content: View>: View {
    @Binding var isShowingContent: Bool
    
    @ViewBuilder let toolbar: () -> Toolbar
    @ViewBuilder let content: () -> Content
    
    @Environment(\.floatingPanel) var panel
    
    var body: some View {
        
        VStack(spacing: 0) {
            toolbar()
            if isShowingContent {
                Divider()
                content()
            }
            Spacer(minLength: 0)
        }
        .background {
            VisualEffectView(material: .sidebar)
        }
        .frame(
            minWidth: 512,
            minHeight: isShowingContent ? 512 : toolbarHeight,
            idealHeight: isShowingContent ? 512 : toolbarHeight,
            maxHeight: isShowingContent ? .infinity : toolbarHeight
        )
        .clipShape(.rect(cornerRadius: 10))
    }
    
    private let toolbarHeight: CGFloat = 60
}
#endif
