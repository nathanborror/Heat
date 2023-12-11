import SwiftUI
import HeatKit

struct ChatMessageContainerView: View {
    let message: Message
    let paragraphs: [String]
    
    init(message: Message) {
        self.message = message
        self.paragraphs = message.content.split(separator: "\n\n").map { String($0) }
    }
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(paragraphs.indices, id: \.self) { index in
                ChatMessageTextView(text: paragraphs[index], isStreaming: !message.done)
                    .messageBubble(message)
                    .messageSpacing(message)
            }
        }
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
        case .system: return .clear
        case .assistant: return .primary.opacity(0.07)
        case .user: return .accentColor
        }
    }
    
    var foregroundColor: Color {
        switch message.role {
        case .system: return .secondary
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
            case .system:
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
    
    func messageBubble(_ message: Message) -> some View {
        self.modifier(ChatMessageBubbleModifier(message: message))
    }
    
    func messageSpacing(_ message: Message) -> some View {
        self.modifier(ChatMessageSpacingModifier(message: message))
    }
}
