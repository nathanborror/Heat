import SwiftUI
import GenKit
import HeatKit
import MarkdownUI
import Splash

struct MessageView: View {
    @Environment(Store.self) var store
    
    let message: Message
    
    var body: some View {
        Group {
            if message.role == .system && PreferencesStore.shared.preferences.debug {
                MessageSystemView(message: message)
            }
            if message.role == .user {
                MessageViewText(message: message)
                    .messageSpacing(message)
                    .messageAttachments(message)
                    .padding(.vertical, 8)
            }
            if message.role == .assistant && message.toolCalls == nil {
                MessageViewText(message: message)
                    .messageSpacing(message)
                    .messageAttachments(message)
                    .padding(.vertical, 8)
            }
            if message.role == .assistant && message.toolCalls != nil {
                if message.content != nil {
                    MessageViewText(message: message)
                        .messageSpacing(message)
                        .padding(.vertical, 8)
                }
                if PreferencesStore.shared.preferences.debug {
                    MessageToolCall(message: message)
                }
            }
            if message.role == .tool {
                MessageTool(message: message)
            }
        }
    }
}

struct MessageViewText: View {
    @Environment(Store.self) var store
    @Environment(\.colorScheme) private var colorScheme
    
    let message: Message
    
    var body: some View {
        switch message.role {
        case .user:
            Markdown(message.content ?? "")
                .markdownTheme(.mate)
                .markdownCodeSyntaxHighlighter(.splash(theme: .sunset(withFont: .init(size: monospaceFontSize))))
                .textSelection(.enabled)
        case .assistant:
            VStack(alignment: .leading) {
                Markdown(message.content ?? "")
                    .markdownTheme(.mate)
                    .markdownCodeSyntaxHighlighter(.splash(theme: .sunset(withFont: .init(size: monospaceFontSize))))
                    .textSelection(.enabled)
            }
        default:
            EmptyView()
        }
    }
    
    struct ParsedText {
        var taggedContent: [String: String]
        var readableContent: String
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
