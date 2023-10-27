import SwiftUI
import HeatKit

struct ChatMessageContainerView: View {
    let agent: Agent?
    let message: Message
    
    var body: some View {
        ChatMessageTextView(text: message.content, isStreaming: !message.done)
            .messageBubble(message)
            .messageSpacing(message)
            //.messageAuthorship(message, agent: agent)
    }
    
    var tail = Text(Image(systemName: "poweron")).foregroundColor(.primary).fontWeight(.bold)
}

struct ChatMessageTextView: View {
    let text: String?
    let isStreaming: Bool
    
    var body: some View {
        Text(LocalizedStringKey(text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")) + (isStreaming ? tail : Text(""))
    }
    
    var tail: Text {
        Text(Image(systemName: "poweron"))
            .fontWeight(.bold)
    }
}

// Modifiers

struct ChatMessageBubbleModifier: ViewModifier {
    let message: Message
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, paddingHorizontal)
            .padding(.vertical, paddingVertical)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
    
    var backgroundColor: Color {
        switch message.role {
        case .assistant: return .primary.opacity(0.07)
        case .user: return .accentColor
        }
    }
    
    var foregroundColor: Color {
        switch message.role {
        case .assistant: return .primary
        case .user: return .white
        }
    }
    
    #if os(macOS)
    private let paddingHorizontal: CGFloat = 12
    private let paddingVertical: CGFloat = 8
    private let cornerRadius: CGFloat = 16
    #else
    private let paddingHorizontal: CGFloat = 16
    private let paddingVertical: CGFloat = 10
    private let cornerRadius: CGFloat = 20
    #endif
}

struct ChatMessageSpacingModifier: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        HStack {
            switch message.role {
            case .assistant:
                content
                Spacer(minLength: 16)
            case .user:
                Spacer(minLength: 16)
                content
            }
        }
    }
}

struct ChatMessageAuthorshipModifier: ViewModifier {
    let agent: Agent?
    let message: Message
    
    func body(content: Content) -> some View {
        if message.role == .assistant, let agent = agent {
            HStack(alignment: .bottom) {
                PictureView(picture: agent.picture)
                    .frame(width: 32, height: 32)
                    .clipShape(Squircle())
                content
            }
        } else {
            content
        }
    }
}

extension View {
    
    func messageBubble(_ message: Message) -> some View {
        self.modifier(ChatMessageBubbleModifier(message: message))
    }
    
    func messageSpacing(_ message: Message) -> some View {
        self.modifier(ChatMessageSpacingModifier(message: message))
    }
    
    func messageAuthorship(_ message: Message, agent: Agent?) -> some View {
        self.modifier(ChatMessageAuthorshipModifier(agent: agent, message: message))
    }
}
