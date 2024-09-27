import SwiftUI
import GenKit
import HeatKit

struct MessageView: View {
    @Environment(\.debug) private var debug
    
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if debug {
                Text(message.role.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            switch message.role {
            case .system:
                if debug {
                    MessageSystemView(message: message)
                }
            case .user:
                MessageViewText(message: message)
                    .messageSpacing(message)
                    .messageAttachments(message)
            case .assistant:
                if message.toolCalls == nil {
                    MessageViewText(message: message)
                        .messageSpacing(message)
                        .messageAttachments(message)
                } else {
                    if message.content != nil {
                        MessageViewText(message: message)
                            .messageSpacing(message)
                    }
                    MessageToolCall(message: message)
                }
            case .tool:
                MessageTool(message: message)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }
}

struct MessageViewText: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch message.role {
            case .user:
                ContentView(text: message.content, role: .user)
            case .assistant:
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(contents.indices, id: \.self) { index in
                        switch contents[index] {
                        case .text(let text):
                            ContentView(text: text, role: .assistant)
                        case .tag(let tag):
                            TagView(tag: tag)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, -12)
                        }
                    }
                }
            default:
                EmptyView()
            }
        }
        .fixedSize(horizontal: false, vertical: true) // Prevents occasional word truncation
    }
    
    var contents: [ContentParser.Result.Content] {
        guard case .assistant = message.role else { return [] }
        guard let content = message.content else { return [] }
        guard let results = try? parser.parse(input: content, tags: ["thinking", "artifact", "output"]) else { return [] }
        return results.contents
    }
    
    private let parser = ContentParser.shared
}

// Modifiers

struct MessageViewSpacing: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            switch message.role {
            case .system, .tool, .assistant:
                content
            case .user:
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint, in: .rect(cornerRadius: 10))
                    .padding(.leading, -12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MessageViewAttachments: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        if message.attachments.isEmpty {
            content
        } else {
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(message.attachments.indices, id: \.self) { index in
                            switch message.attachments[index] {
                            case .agent(let agentID):
                                Text(agentID)
                            case .asset(let asset):
                                PictureView(asset: asset)
                                    .frame(width: 300, height: 300)
                                    .clipShape(.rect(cornerRadius: 10))
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
                .scrollClipDisabled()
                content
            }
        }
    }
}

extension View {
    
    func messageSpacing(_ message: Message) -> some View {
        self.modifier(MessageViewSpacing(message: message))
    }
    
    func messageAttachments(_ message: Message) -> some View {
        self.modifier(MessageViewAttachments(message: message))
    }
}
