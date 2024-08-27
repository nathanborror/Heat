import SwiftUI
import GenKit
import HeatKit
import MarkdownUI

struct MessageView: View {
    @Environment(\.debug) private var debug
    @Environment(\.useMarkdown) private var useMarkdown
    
    let message: Message
    
    var body: some View {
        Group {
            if message.role == .system && debug {
                MessageSystemView(message: message)
            }
            if message.role == .user {
                MessageViewText(message: message)
                    .messageSpacing(message)
                    .messageAttachments(message)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
            }
            if message.role == .assistant && message.toolCalls == nil {
                MessageViewText(message: message)
                    .messageSpacing(message)
                    .messageAttachments(message)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
            }
            if message.role == .assistant && message.toolCalls != nil {
                if message.content != nil {
                    MessageViewText(message: message)
                        .messageSpacing(message)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                }
                if debug {
                    MessageToolCall(message: message)
                }
            }
            if message.role == .tool {
                MessageTool(message: message)
            }
        }
        .textSelection(.enabled)
    }
}

struct MessageViewText: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.useMarkdown) private var useMarkdown
    
    let message: Message
    
    var body: some View {
        Group {
            switch message.role {
            case .user:
                if useMarkdown {
                    Markdown(message.content ?? "")
                        .markdownTheme(.app)
                        .markdownCodeSyntaxHighlighter(.app)
                } else {
                    Text(message.content ?? "")
                }
            case .assistant:
                if useMarkdown {
                    Markdown(message.content ?? "")
                        .markdownTheme(.app)
                        .markdownCodeSyntaxHighlighter(.app)
                } else {
                    Text(message.content ?? "")
                }
            default:
                EmptyView()
            }
        }
        .fixedSize(horizontal: false, vertical: true) // Prevents occasional word truncation
    }
    
    struct ParsedText {
        var taggedContent: [String: String]
        var readableContent: String
    }
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
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 10))
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
