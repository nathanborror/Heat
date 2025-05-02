import SwiftUI
import SharedKit
import HeatKit

struct ConversationView: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State var conversationViewModel: ConversationViewModel

    init(file: File) {
        self.fileID = file.id
        self.conversationViewModel = .init(file: file)
    }

    var body: some View {
        MessageList()
            .navigationTitle(conversationViewModel.title)
            #if os(macOS)
            .navigationSubtitle(conversationViewModel.subtitle)
            #endif
            .safeAreaInset(edge: .bottom, alignment: .center) {
                MessageField { (prompt, context, toolIDs) in
                    handleSubmit(prompt, context: context, toolIDs: toolIDs)
                }
                .background(.background)
            }
            .environment(conversationViewModel)
            .onChange(of: fileID) { oldValue, newValue in
                handleLoad()
            }
            .onAppear {
                handleLoad()
            }
    }

    func handleLoad() {
        Task {
            do {
                let conversation = try await API.shared.fileData(fileID, type: Conversation.self)
                conversationViewModel.read(conversation)
            } catch {
                state.log(error: error)
            }
        }
    }

    func handleSubmit(_ prompt: String, context: [String: String]? = nil, toolIDs: Set<String>? = nil) {
        Task {
            do {
                if conversationViewModel.conversation.isEmpty {
                    let conversation = try await API.shared.fileData(fileID, type: Conversation.self)
                    conversationViewModel.read(conversation)
                }

                // Augment the tool set associated with the conversation, it's a better user experience to keep
                // around tools used with custom instructions so the assistant can use them for followup questions.
                if let toolIDs {
                    var conversation = try state.file(Conversation.self, fileID: fileID)
                    conversation.toolIDs.formUnion(toolIDs)
                    try await state.fileUpdate(conversation, fileID: fileID)
                }

                try await conversationViewModel.generate(
                    chat: prompt,
                    context: context?.mapValues { Value.string($0) } ?? [:]
                )
            } catch {
                state.log(error: error)
            }
        }
    }
}
