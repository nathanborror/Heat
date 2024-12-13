import SwiftUI
import GenKit
import HeatKit

struct MessageView: View {
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
                MessageContent(message.content, for: message.role, agentID: message.metadata?.agentID)
                    .messageSpacing(message)
            case .user:
                MessageContent(message.content, for: message.role, agentID: message.metadata?.agentID)
                    .messageSpacing(message)
            case .assistant:
                MessageContent(message.content, for: message.role, agentID: message.metadata?.agentID)
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
    @Environment(AppState.self) private var state

    let role: Message.Role

    init(_ role: Message.Role) {
        self.role = role
    }

    var body: some View {
        if state.debug {
            Text(role.rawValue)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct MessageContent: View {
    @Environment(AppState.self) var state
    @Environment(\.colorScheme) private var colorScheme

    let content: [Message.Content]?
    let role: Message.Role
    let agentID: Agent.ID?

    init(_ content: [Message.Content]?, for role: Message.Role, agentID: String? = nil) {
        self.content = content
        self.role = role
        self.agentID = (agentID != nil) ? .init(agentID!) : nil
    }

    var body: some View {
        if let content {
            VStack(alignment: .leading, spacing: 12) {
                switch role {
                case .system:
                    contentBody
                case .user:
                    contentBody
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

    var contentBody: some View {
        Group {
            if let content {
                ForEach(content.indices, id: \.self) { index in
                    switch content[index] {
                    case .text(let text):
                        RenderText(text, role: role)
                    case .image(let data, _):
                        PictureView(data: data)
                            .frame(width: 200, height: 200)
                            .clipShape(.rect(cornerRadius: 5))
                            .padding(.bottom, 6)
                        //RenderText("{Image}", role: role)
                    case .audio:
                        RenderText("{Audio}", role: role)
                    }
                }
            }
        }
    }

    var contents: [ContentParser.Result.Content] {
        // TODO: Handle multiple content items
        guard case .text(let text) = content?.first else { return [] }

        // Start with default tags to look for, if the message has a agentID associated with it
        // look for the tags its agent is expecting to output.
        var tags = ["thinking", "artifact", "output", "reflection", "image_search_query"]
        if let agentID, let agent = try? state.agentsProvider.get(agentID) {
            tags = agent.tags
        }

        guard let results = try? parser.parse(input: text, tags: tags) else { return [] }
        return results.contents
    }

    private let parser = ContentParser.shared
}

// Modifiers

struct MessageViewSpacing: ViewModifier {
    let message: Message

    func body(content: Content) -> some View {
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
}

extension View {

    func messageSpacing(_ message: Message) -> some View {
        self.modifier(MessageViewSpacing(message: message))
    }
}
