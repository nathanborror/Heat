import SwiftUI
import HeatKit

struct ConversationView: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State private var conversationViewModel: ConversationViewModel? = nil

    var body: some View {
        Group {
            if conversationViewModel == nil {
                VStack {
                    Spacer()
                    ContentUnavailableView {
                        Label("No conversation selected", systemImage: "bubble.fill")
                    } description: {
                        Text("Select a conversation or create a new one.")
                    }
                    Spacer()
                }
            } else {
                MessageList()
            }
        }
        .environment(conversationViewModel)
        .navigationTitle(conversationViewModel?.title ?? "Heat")
        #if os(macOS)
        .navigationSubtitle(conversationViewModel?.subtitle ?? "")
        #endif
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MessageField { prompt, instruction in
                handleSubmit(prompt, instruction: instruction)
            }
            .background(.background)
        }
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
                let file = try API.shared.file(fileID)
                let conversation = try await API.shared.fileData(fileID, type: Conversation.self)
                conversationViewModel = .init(conversation: conversation, file: file)
            } catch {
                state.log(error: error)
            }
        }
    }

    func handleSubmit(_ prompt: String, instruction: Instruction? = nil) {
        Task {

            // Create new conversation if one doesn't exist
            if conversationViewModel == nil {
                let fileID = try await state.fileCreateConversation()
                let file = try API.shared.file(fileID)
                let conversation = try await API.shared.fileData(fileID, type: Conversation.self)
                conversationViewModel = .init(conversation: conversation, file: file)
            }

            // Generate conversation response
            do {
                try await conversationViewModel?.generate(chat: prompt)
            } catch {
                state.log(error: error)
            }
        }
    }
}
