import SwiftUI
import SwiftData
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "App")

struct ConversationView: View {
    @Environment(TemplatesProvider.self) var templatesProvider
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
                    VStack {
                        Text("Assistant picker")
                            .foregroundStyle(.secondary)
                        Menu {
                            ForEach(templatesProvider.templates.filter { $0.kind == .assistant }) { template in
                                Button(template.name) {
                                    Task {
                                        var preferences = preferencesProvider.preferences
                                        preferences.defaultAssistantID = template.id
                                        try await preferencesProvider.upsert(preferences)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let templateID = preferencesProvider.preferences.defaultAssistantID, let template = try? templatesProvider.get(templateID) {
                                    Text(template.name)
                                } else {
                                    Text("Pick assistant")
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.background)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            }
                        }
                    }
                    .font(.subheadline)
                    .buttonStyle(.plain)
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
                guard let templateID = preferencesProvider.preferences.defaultAssistantID else { return }
                let template = try templatesProvider.get(templateID)
                let conversation = try await conversationsProvider.create(instructions: template.instructions, toolIDs: template.toolIDs)
                
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
