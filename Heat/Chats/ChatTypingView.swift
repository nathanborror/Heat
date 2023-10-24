import SwiftUI
import HeatKit

struct ChatTypingIndicatorView: View {
    
    let alignment: Alignment
    let agent: Agent?
    let foregroundColor: Color
    let backgroundColor: Color
    
    enum Alignment {
        case leading
        case trailing
    }
    
    init(_ alignment: Alignment, agent: Agent? = nil, foregroundColor: Color = .secondary, backgroundColor: Color = .secondary.opacity(0.15)) {
        self.alignment = alignment
        self.agent = agent
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            switch alignment {
            case .leading:
                if let agent = agent {
                    PictureView(picture: agent.picture)
                        .frame(width: 32, height: 32)
                        .clipShape(Squircle())
                }
                ChatTypingEllipsis(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
                Spacer()
            case .trailing:
                Spacer()
                ChatTypingEllipsis(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
            }
        }
    }
}

struct ChatTypingEllipsis: View {
    let foregroundColor: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<3, id: \.self) { index in
                ChatTypingDot(color: foregroundColor, size: dotSize, delay: Double(index)*0.2)
            }
        }
        .padding(.horizontal, paddingHorizontal)
        .padding(.vertical, paddingVertical)
        .background(backgroundColor)
        .clipShape(.rect(cornerRadius: cornerRadius))
    }
    
    #if os(macOS)
    private let dotSize: CGFloat = 5
    private let dotSpacing: CGFloat = 2
    private let paddingHorizontal: CGFloat = 13
    private let paddingVertical: CGFloat = 13
    private let cornerRadius: CGFloat = 16
    #else
    private let dotSize: CGFloat = 7
    private let dotSpacing: CGFloat = 3
    private let paddingHorizontal: CGFloat = 16
    private let paddingVertical: CGFloat = 16
    private let cornerRadius: CGFloat = 20
    #endif
}

struct ChatTypingDot: View {
    let color: Color
    let size: CGFloat
    let delay: TimeInterval
    
    @State private var isVisible = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size)
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0.2)
            .animation(.easeInOut(duration: 0.6).repeatForever().delay(delay), value: isVisible)
            .onAppear { self.isVisible = true }
    }
}

#Preview {
    VStack {
        ChatTypingIndicatorView(.leading)
        ChatTypingIndicatorView(.trailing)
        ChatTypingIndicatorView(.trailing, foregroundColor: .accentColor, backgroundColor: .accentColor.opacity(0.1))
    }
    .padding(.horizontal)
}
