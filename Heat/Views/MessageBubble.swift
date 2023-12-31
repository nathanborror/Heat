import SwiftUI
import GenKit

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        MessageBubbleText(text: message.content, finishReason: message.finishReason)
            .messageBubbleStyle(message)
            .messageBubbleSpacing(message)
    }
}

struct MessageBubbleText: View {
    let text: String?
    let finishReason: Message.FinishReason?
    
    var body: some View {
        Text(LocalizedStringKey(text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")) + tail
    }
    
    var tail: Text {
        switch finishReason {
        case .stop, .length, .toolCalls, .contentFilter, .cancelled:
            Text("")
        case .none:
            Text(Image(systemName: "poweron"))
                .fontWeight(.bold)
        }
    }
}

// Modifiers

struct MessageBubbleStyle: ViewModifier {
    let message: Message
    
    func body(content: Content) -> some View {
        switch message.role {
        case .system, .tool:
            content
                .padding(.vertical, paddingVertical)
                .foregroundStyle(foregroundColor)
                .font(.footnote)
        case .assistant:
            content
                .padding(.vertical, paddingVertical)
        case .user:
            content
                .padding(.horizontal, paddingHorizontal)
                .padding(.vertical, paddingVertical)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
    
    var backgroundColor: Color {
        switch message.role {
        case .system, .tool: return .clear
        case .assistant: return .primary.opacity(0.07)
        case .user: return .accentColor
        }
    }
    
    var foregroundColor: Color {
        switch message.role {
        case .system, .tool: return .secondary
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

struct MessageBubbleSpacing: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
        HStack {
            switch message.role {
            case .system, .tool:
                content
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

extension View {
    
    func messageBubbleStyle(_ message: Message) -> some View {
        self.modifier(MessageBubbleStyle(message: message))
    }
    
    func messageBubbleSpacing(_ message: Message) -> some View {
        self.modifier(MessageBubbleSpacing(message: message))
    }
}

