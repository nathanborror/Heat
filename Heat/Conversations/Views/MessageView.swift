import SwiftUI
import GenKit
import HeatKit
import MarkdownUI
import Splash

struct MessageView: View {
    let message: Message
    
    var body: some View {
        if message.content != nil {
            MessageViewText(message: message, finishReason: message.finishReason)
                .messageSpacing(message)
                .messageAttachments(message)
                .textSelection(.enabled)
                .padding(.vertical, 8)
                .opacity(message.kind == .instruction ? 0.3 : 1)
        }
    }
}

struct MessageViewText: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let message: Message
    let finishReason: Message.FinishReason?
    
    var body: some View {
        switch message.role {
        case .user:
            Markdown(message.content ?? "")
                .markdownTheme(.mate)
                .markdownCodeSyntaxHighlighter(.splash(theme: .sunset(withFont: .init(size: monospaceFontSize))))
        case .assistant:
            Markdown(message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                .markdownTheme(.mate)
                .markdownCodeSyntaxHighlighter(.splash(theme: .sunset(withFont: .init(size: monospaceFontSize))))
        case .system, .tool:
            Text(message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                .font(.subheadline)
                .foregroundStyle(message.kind == .error ? .red : .secondary)
        }
    }
    
    #if os(macOS)
    var monospaceFontSize: CGFloat = 11
    #else
    var monospaceFontSize: CGFloat = 12
    #endif
}

// Modifiers

struct MessageViewSpacing: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            switch message.role {
            case .system, .tool:
                content
                Spacer()
            case .assistant:
                content
                Spacer()
            case .user:
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.leading, -12)
                Spacer()
            }
        }
    }
    
    #if os(macOS)
    var roleFont = Font.body
    var roleOpacity = 0.5
    var roleSymbolOpacity = 0.5
    #else
    var roleFont = Font.system(size: 14)
    var roleOpacity = 0.3
    var userSymbolColor = Color.primary.opacity(0.3)
    var assistantSymbolColor = Color.indigo
    #endif
}

struct MessageViewAttachments: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        if message.attachments.isEmpty {
            content
        } else {
            VStack {
                HStack {
                    if message.role == .user { Spacer() }
                    ForEach(message.attachments.indices, id: \.self) { index in
                        switch message.attachments[index] {
                        case .agent(let agentID):
                            Text(agentID)
                        case .asset(let asset):
                            PictureView(asset: asset)
                                .frame(width: 200, height: 200)
                                .clipShape(.rect(cornerRadius: 10))
                        default:
                            EmptyView()
                        }
                    }
                    if message.role == .assistant { Spacer() }
                }
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
