import SwiftUI
import GenKit
import HeatKit

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        MessageBubbleText(text: message.content, finishReason: message.finishReason)
            .messageBubbleStyle(message)
            .messageBubbleSpacing(message)
            .messageBubbleAttachments(message)
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
                .font(.footnote)
                .padding(.vertical, paddingVertical)
                .foregroundStyle(foregroundColor)
        case .assistant:
            content
                .font(font)
                .lineSpacing(2)
                .padding(.vertical, paddingVertical)
        case .user:
            content
                .font(font)
                .padding(.horizontal, paddingHorizontal)
                .padding(.vertical, paddingVertical)
                .foregroundStyle(foregroundColor)
                .background(backgroundColor)
                .clipShape(.rect(cornerRadius: cornerRadius))
        }
    }
    
    var backgroundColor: SwiftUI.Color {
        switch message.role {
        case .system, .tool: return .clear
        case .assistant: return .primary.opacity(0.07)
        case .user: return .accentColor
        }
    }
    
    var foregroundColor: SwiftUI.Color {
        switch message.role {
        case .system, .tool: return .secondary
        case .assistant: return .primary
        case .user: return .white
        }
    }
    
    #if os(macOS)
    private let paddingHorizontal: CGFloat = 12
    private let paddingVertical: CGFloat = 6
    private let cornerRadius: CGFloat = 10
    private let font: Font = .body
    #else
    private let paddingHorizontal: CGFloat = 16
    private let paddingVertical: CGFloat = 10
    private let cornerRadius: CGFloat = 20
    private let font: Font = .body
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

struct MessageBubbleAttachments: ViewModifier {
    let message: Message
        
    func body(content: Content) -> some View {
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
                    }
                }
                if message.role == .assistant { Spacer() }
            }
            content
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
    
    func messageBubbleAttachments(_ message: Message) -> some View {
        self.modifier(MessageBubbleAttachments(message: message))
    }
}

#Preview {
    let store = Store.preview
    return NavigationStack {
        ConversationView(conversationID: .constant(nil))
    }
    .environment(store)
}
