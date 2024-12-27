import SwiftUI
import GenKit
import HeatKit

struct MessageView: View {
    let message: Message

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
           switch message.role {
            case .system:
               SystemContentsView(message.contents)
            case .user:
               UserContentsView(message.contents)
            case .assistant:
               AssistantContentsView(message.contents)
               ToolCalls(message.toolCalls) { toolCall in
                   Text(toolCall.function.name)
                   Text(toolCall.function.arguments)
               }
            case .tool:
               ToolContentsView(message.contents)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Contents

struct SystemContentsView: View {
    let contents: [Message.Content]

    init(_ contents: [Message.Content]?) {
        self.contents = contents ?? []
    }

    var body: some View {
        ContentsView(contents)
            .render(role: .system)
    }
}

struct AssistantContentsView: View {
    let contents: [Message.Content]

    init(_ contents: [Message.Content]?) {
        self.contents = contents ?? []
    }

    var body: some View {
        ContentsView(contents)
            .render(role: .assistant)
    }
}

struct UserContentsView: View {
    let contents: [Message.Content]

    init(_ contents: [Message.Content]?) {
        self.contents = contents ?? []
    }

    var body: some View {
        ContentsView(contents)
            .render(role: .user)
    }
}

struct ToolContentsView: View {
    let contents: [Message.Content]

    init(_ contents: [Message.Content]?) {
        self.contents = contents ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(contents.indices, id: \.self) {
                switch contents[$0] {
                case .text(let text):
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                case .image(let data, _):
                    PictureView(data: data)
                        .frame(width: 200, height: 200)
                        .clipShape(.rect(cornerRadius: 5))
                case .audio:
                    Text("Audio is unhandled right now.")
                }
            }
        }
    }
}

struct ContentsView: View {
    let contents: [Message.Content]

    init(_ contents: [Message.Content]?) {
        self.contents = contents ?? []
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(contents.indices, id: \.self) {
                switch contents[$0] {
                case .text(let text):
                    RenderText(text, tags: ["thinking", "artifact", "output", "image_search_query"])
                case .image(let data, _):
                    PictureView(data: data)
                        .frame(width: 200, height: 200)
                case .audio:
                    Text("Audio is unhandled right now.")
                }
            }
        }
    }
}

// Tool Calls

struct ToolCalls<Content: View>: View {
    let toolCalls: [ToolCall]
    let content: (ToolCall) -> Content

    init(_ toolCalls: [ToolCall]?, @ViewBuilder content: @escaping (ToolCall) -> Content) {
        self.toolCalls = toolCalls ?? []
        self.content = content
    }

    var body: some View {
        ForEach(toolCalls, id: \.id) { toolCall in
            content(toolCall)
        }
    }
}
