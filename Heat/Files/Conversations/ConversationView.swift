import SwiftUI
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
                MessageField { prompt, instruction in
                    handleSubmit(prompt, instruction: instruction)
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

    func handleSubmit(_ prompt: String, instruction: Instruction? = nil) {
        Task {
            do {
                if conversationViewModel.conversation.isEmpty {
                    let conversation = try await API.shared.fileData(fileID, type: Conversation.self)
                    conversationViewModel.read(conversation)
                }
                try await conversationViewModel.generate(chat: prompt)
            } catch {
                state.log(error: error)
            }
        }
    }
}
