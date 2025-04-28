import SwiftUI
import GenKit
import HeatKit

struct ConversationViewInspector: View {
    @Environment(AppState.self) var state
    @Environment(ConversationViewModel.self) var conversationViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                instructions
                Divider()
                messageList
            }
            .padding()
            .font(.footnote)
            .fontDesign(.monospaced)
            .textSelection(.enabled)
        }
        .navigationTitle("Details")
    }

    var instructions: some View {
        VStack(alignment: .leading) {
            Text("Instructions")
                .fontWeight(.bold)
            Text(conversationViewModel.conversation.instructions)
        }
    }

    var messageList: some View {
        ForEach(conversationViewModel.messages) { message in
            VStack(alignment: .leading) {
                Text(message.role.rawValue.capitalized)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    if let contents = message.contents {
                        ForEach(contents.indices, id: \.self) { index in
                            switch contents[index] {
                            case .text(let text):
                                Text(text)
                            case .image(let image):
                                VStack(alignment: .leading) {
                                    Text("Image (\(image.format))")
                                        .fontWeight(.medium)
                                    Text(image.url.absoluteString)
                                    if let detail = image.detail {
                                        Text(detail)
                                    }
                                }
                                .foregroundStyle(.secondary)
                            case .audio(let audio):
                                VStack(alignment: .leading) {
                                    Text("Audio (\(audio.format))")
                                        .fontWeight(.medium)
                                    Text(audio.url.absoluteString)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let toolCalls = message.toolCalls {
                    ForEach(toolCalls.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(toolCalls[index].function.name)
                                .fontWeight(.medium)
                            Text(toolCalls[index].function.arguments)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
