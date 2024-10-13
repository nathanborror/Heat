import SwiftUI
import GenKit
import HeatKit

struct MessageView: View {
    @Environment(\.debug) private var debug
    
    let message: Message
    let lineLimit: Int
    
    init(_ message: Message, lineLimit: Int = 4) {
        self.message = message
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Render role for all messages in debug mode
            MessageRole(message.role)
            
            // Render message content
            switch message.role {
            case .system:
                MessageContent(message.content, for: message.role, agentID: message.metadata.agentID)
                    .messageSpacing(message)
            case .user:
                MessageContent(message.content, for: message.role, agentID: message.metadata.agentID)
                    .messageSpacing(message)
                MessageAttachments(message.attachments)
                    .messageSpacing(message)
            case .assistant:
                MessageContent(message.content, for: message.role, agentID: message.metadata.agentID)
                    .messageSpacing(message)
                MessageAttachments(message.attachments)
                    .messageSpacing(message)
                MessageToolCalls(message.toolCalls, lineLimit: lineLimit)
                    .messageSpacing(message)
            case .tool:
                MessageTool(message, lineLimit: lineLimit)
                    .messageSpacing(message)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(\.colorScheme) private var colorScheme
    
    let content: String?
    let role: Message.Role
    let agentID: String?
    
    init(_ content: String?, for role: Message.Role, agentID: String? = nil) {
        self.content = content
        self.role = role
        self.agentID = agentID
    }
    
    var body: some View {
        if let content {
            VStack(alignment: .leading, spacing: 12) {
                switch role {
                case .system:
                    RenderText(content, formatter: .text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .user:
                    RenderText(content, role: .user)
                case .assistant, .tool:
                    ForEach(contents.indices, id: \.self) { index in
                        switch contents[index] {
                        case let .text(text):
                            RenderText(text)
                        case let .tag(tag):
                            TagView(tag)
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true) // Prevents occasional word truncation
        }
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = content else { return [] }
        
        // Start with default tags to look for, if the message has a agentID associated with it
        // look for the tags its agent is expecting to output.
        var tags = ["thinking", "artifact", "output", "reflection", "image_search_query"]
        if let agentID, let agent = try? agentsProvider.get(agentID) {
            tags = agent.tags
        }
        
        guard let results = try? parser.parse(input: content, tags: tags) else { return [] }
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
                    .padding(.horizontal, 12)
            case .user:
                content
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint, in: .rect(cornerRadius: 10))
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
