import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel

    @State private var messageInputText = ""
    @State private var messageInputState: MessageInputViewState = .init()
    
    @State private var sheet: Sheet? = nil
    
    @State private var isShowingError = false
    @State private var error: ConversationViewModelError? = nil
    
    struct Sheet: Identifiable, Equatable {
        var id: String
        var template: Template?
        
        static let history = Sheet(id: "history")
        static let preferences = Sheet(id: "preferences")
        static let templateNew = Sheet(id: "templateNew")
        static let templateEdit = Sheet(id: "templateEdit")
        
        public static func == (lhs: Sheet, rhs: Sheet) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    ConversationScrollViewMarker(id: "scrollViewTop")
                    if viewModel.conversationID != nil {
                        ChatHistoryView()
                    } else {
                        ChatTemplateList(
                            size: geo.size,
                            select: handleSelect,
                            edit: handleEdit,
                            delete: handleDelete
                        )
                    }
                    ConversationScrollViewMarker(id: "scrollViewBottom")
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.conversationID) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onChange(of: viewModel.conversation) { _, _ in
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
                .onAppear {
                    scrollViewProxy.scrollTo(scrollToPosition, anchor: .bottom)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .background(.background)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageInput(
                text: $messageInputText,
                submit: handleGenerateResponse,
                stop: viewModel.cancel
            )
            .environment(messageInputState)
            .padding(.vertical, 8)
            .background(.background)
        }
        .toolbar {
            #if os(macOS)
            Button(action: { sheet = .preferences }) {
                Label("Preferences", systemImage: "slider.horizontal.3")
            }
            Button(action: { sheet = .history }) {
                Label("History", systemImage: "archivebox")
            }
            Button(action: handleClear) {
                Label("New Chat", systemImage: "plus")
            }
            .disabled(viewModel.conversationID == nil)
            #else
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: { sheet = .templateNew }) {
                        Label("New Template", systemImage: "plus")
                    }
                    Button(action: { sheet = .history }) {
                        Label("History", systemImage: "archivebox")
                    }
                    Button(action: { sheet = .preferences }) {
                        Label("Preferences", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
            ToolbarItem {
                Button(action: handleClear) {
                    Label("New Conversation", systemImage: "plus")
                }.disabled(viewModel.conversationID == nil)
            }
            #endif
        }
        .sheet(item: $sheet) { sheet in
            NavigationStack {
                switch sheet {
                case Sheet.history:
                    ConversationListView(selection: handleSelect)
                case Sheet.preferences:
                    PreferencesForm()
                case Sheet.templateNew:
                    TemplateForm(template: .empty)
                case Sheet.templateEdit:
                    TemplateForm(template: sheet.template ?? .empty)
                default:
                    EmptyView()
                }
            }
            .environment(store)
            .environment(viewModel)
        }
        .alert(isPresented: $isShowingError, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                isShowingError = false
                error = nil
            }
            Button("Preferences") {
                sheet = .preferences
                isShowingError = false
                error = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
    }
    
    var scrollToPosition: String {
        if viewModel.conversationID != nil {
            "scrollViewBottom"
        } else {
            "scrollViewTop"
        }
    }
    
    func handleClear() {
        viewModel.conversationID = nil
        messageInputState.change(.resting)
    }
    
    func handleSelect(template: Template) {
        let conversation = Conversation(messages: template.messages)
        store.upsert(conversation: conversation)

        // Switch conversation
        handleSelect(conversationID: conversation.id)
        
        // Genrate an introduction
        do {
            try viewModel.generateResponse()
        } catch let error as ConversationViewModelError {
            self.error = error
            isShowingError = true
        } catch {
            logger.error("failed to generate introduction: \(error)")
        }
        
        // Show keyboard
        messageInputState.change(.focused)
    }
    
    func handleEdit(template: Template) {
        var sheet = Sheet.templateEdit
        sheet.template = template
        self.sheet = sheet
    }
    
    func handleDelete(template: Template) {
        store.delete(template: template)
    }
    
    func handleSelect(conversationID: String) {
        viewModel.conversationID = conversationID
    }
    
    func handleGenerateResponse(content: String) {
        if viewModel.conversationID == nil {
            let conversation = Conversation(messages: Template.assistant.messages)
            store.upsert(conversation: conversation)
            handleSelect(conversationID: conversation.id)
        }
        do {
            try viewModel.generateResponse(content: content)
        } catch let error as ConversationViewModelError {
            self.error = error
            isShowingError = true
        } catch {
            logger.error("failed to generate response: \(error)")
        }
    }
}

struct ChatTemplateList: View {
    @Environment(Store.self) private var store
    
    typealias Callback = (Template) -> Void
    
    let size: CGSize
    let select: Callback
    let edit: Callback
    let delete: Callback
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.templates) { template in
                TemplateTile(
                    template: template,
                    height: size.width/heightDivisor,
                    selection: select
                )
                .contextMenu {
                    Button(action: { edit(template) }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { delete(template) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let heightDivisor: CGFloat = 3.5
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let heightDivisor: CGFloat = 3
    #endif
}

struct ChatHistoryView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel
    
    var body: some View {
        LazyVStack {
            ForEach(viewModel.messages) { message in
                MessageBubble(message: message)
            }
            if let conversation = viewModel.conversation {
                if conversation.state == .processing {
                    TypingIndicator(.leading)
                }
            }
        }
        .padding()
    }
}

struct ConversationScrollViewMarker: View {
    let id: String
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .id(id)
    }
}

// MARK: - Previews

#Preview("Template Picker") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: store)
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}

#Preview("Conversation") {
    let store = Store.preview
    let viewModel = ConversationViewModel(store: store)
    
    let conversation = store.conversations.first!
    viewModel.conversationID = conversation.id
    
    return NavigationStack {
        ConversationView()
    }
    .environment(store)
    .environment(viewModel)
}
