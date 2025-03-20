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
               ForEachToolCall(message.toolCalls) { toolCall in
                   ToolCallView(toolCall)
               }
            case .tool:
               ToolContentsView(message)
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
    let message: Message

    @State var disclosed = false

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                disclosed.toggle()
            } label: {
                ToolResponseName(message.name ?? "Unknown Tool")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if disclosed {
                VStack(alignment: .leading) {
                    if let contents = message.contents {
                        ForEach(contents.indices, id: \.self) { index in
                            switch contents[index] {
                            case .text(let text):
                                Text(text)
                                    .padding(.leading)
                                    .overlay(
                                        Rectangle()
                                            .fill(.primary.opacity(0.5))
                                            .frame(width: 1)
                                            .frame(maxHeight: .infinity)
                                            .opacity(0.5),
                                        alignment: .leading
                                    )
                            case .image(let data, _):
                                PictureView(data: data)
                                    .frame(width: 300, height: 300)
                                    .clipShape(.rect(cornerRadius: 10))
                            case .audio:
                                Text("Audio")
                            }
                        }
                    }
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
        if !contents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(contents.indices, id: \.self) {
                    switch contents[$0] {
                    case .text(let text):
                        RenderText(text, tags: ["thinking", "think", "artifact", "output", "image_search_query"])
                    case .image(let data, _):
                        PictureView(data: data)
                            .frame(width: 200, height: 200)
                            .clipShape(.rect(cornerRadius: 10))
                    case .audio:
                        Text("Audio is unhandled right now.")
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true) // HACK: Prevents occasional word truncation
        }
    }
}

// Tool Calls

struct ForEachToolCall<Content: View>: View {
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

struct ToolCallView: View {
    let toolCall: ToolCall

    @State var disclosed = false

    init(_ toolCall: ToolCall) {
        self.toolCall = toolCall
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                disclosed.toggle()
            } label: {
                ToolCallName(toolCall.function.name)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if disclosed {
                Text(toolCall.function.arguments)
                    .padding(.leading)
                    .overlay(
                        Rectangle()
                            .fill(.primary.opacity(0.5))
                            .frame(width: 1)
                            .frame(maxHeight: .infinity),
                        alignment: .leading
                    )
                    .opacity(0.5)
            }
        }
    }
}

struct ToolCallName: View {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        if let tool = Toolbox(name: name) {
            switch tool {
            case .generateImages:
                Text("Generating image(s)...")
            case .searchCalendar:
                Text("Searching calendar...")
            case .searchWeb:
                Text("Searching web...")
            case .browseWeb:
                Text("Browsing website...")
            }
        } else {
            Text("Unknown tool...")
        }
    }
}

// Tool Responses

struct ToolResponseName: View {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    var body: some View {
        if let tool = Toolbox(name: name) {
            switch tool {
            case .generateImages:
                Text("Generated image(s)")
            case .searchCalendar:
                Text("Searched calendar")
            case .searchWeb:
                Text("Searched web")
            case .browseWeb:
                Text("Browsed website")
            }
        } else {
            Text("Unknown tool")
        }
    }
}
