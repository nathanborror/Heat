import SwiftUI
import GenKit
import HeatKit

struct MessageView: View {
    @Environment(\.debug) private var debug
    
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Render role for all messages in debug mode
            MessageRole(message.role)
            
            // Render message content
            switch message.role {
            case .system:
                MessageContent(message.content, for: message.role)
                    .messageSpacing(message)
            case .user:
                MessageContent(message.content, for: message.role)
                    .messageSpacing(message)
                MessageAttachments(message.attachments)
            case .assistant:
                MessageContent(message.content, for: message.role)
                    .messageSpacing(message)
                MessageAttachments(message.attachments)
                MessageToolCalls(message.toolCalls)
            case .tool:
                MessageTool(message: message)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }
}

struct MessageRole: View {
    @Environment(\.debug) private var debug
    
    let role: Message.Role
    
    init(_ role: Message.Role) {
        self.role = role
    }
    
    var body: some View {
        if debug {
            Text(role.rawValue)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct MessageContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let content: String?
    let role: Message.Role
    
    init(_ content: String?, for role: Message.Role) {
        self.content = content
        self.role = role
    }
    
    var body: some View {
        if let content {
            VStack(alignment: .leading, spacing: 0) {
                switch role {
                case .system:
                    RenderText(content, formatter: .text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .user:
                    RenderText(content, role: .user)
                case .assistant:
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(contents.indices, id: \.self) { index in
                            switch contents[index] {
                            case .text(let text):
                                RenderText(text)
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
    }
    
    var contents: [ContentParser.Result.Content] {
        guard case .assistant = role else { return [] }
        guard let content = content else { return [] }
        guard let results = try? parser.parse(input: content, tags: ["thinking", "artifact", "output", "image_search_query"]) else { return [] }
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

extension View {
    
    func messageSpacing(_ message: Message) -> some View {
        self.modifier(MessageViewSpacing(message: message))
    }
}
