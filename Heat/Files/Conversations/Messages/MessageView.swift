import SwiftUI
import AVKit
import QuickLook
import GenKit
import HeatKit

struct MessageView: View {
    @Environment(AppState.self) var state

    let message: Message

    @State var isCopied = false
    @State var isPlaying = false
    @State var player: AVPlayer?

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

    @State var isDisclosed = false
    @State var imagePreviewURL: URL? = nil

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                isDisclosed.toggle()
            } label: {
                ToolResponseName(message.name ?? "Unknown Tool")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if isDisclosed {
                ContentsView(message.contents)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            if message.hasImage {
                isDisclosed = true
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
                    case .image(let image):
                        ContentImageView(url: image.url, detail: image.detail)
                    case .audio:
                        Text("Audio is unhandled right now.")
                    case .json:
                        Text("JSON is unhandled right now")
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true) // HACK: Prevents occasional word truncation
        }
    }
}

struct ContentImageView: View {
    let url: URL
    let detail: String?

    @State private var showingPreviewURL: URL? = nil
    @State private var showingDetailText = false

    var body: some View {
        Button {
            showingPreviewURL = url
        } label: {
            PictureView(url: url)
                .frame(width: 300, height: 300)
                .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .quickLookPreview($showingPreviewURL)
        .overlay(alignment: .bottomTrailing) {
            if let detail {
                Button {
                    showingDetailText.toggle()
                } label: {
                    Image(systemName: "text.magnifyingglass")
                        .imageScale(.large)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: .rect(cornerRadius: 5))
                        .foregroundStyle(.white)
                        .padding(5)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingDetailText) {
                    NavigationStack {
                        ContentImagePromptView(text: detail)
                    }
                    #if os(macOS)
                    .frame(width: 300)
                    .frame(maxHeight: 200)
                    #endif
                }
            }
        }
    }
}

struct ContentImagePromptView: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .padding()
        }
        #if !os(macOS)
        .navigationTitle("Prompt")
        #endif
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

    @State var isDisclosed = false

    init(_ toolCall: ToolCall) {
        self.toolCall = toolCall
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                isDisclosed.toggle()
            } label: {
                ToolCallName(toolCall.function.name)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if isDisclosed {
                Text(toolCall.function.arguments)
                    .foregroundStyle(.secondary)
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
