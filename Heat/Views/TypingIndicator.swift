import SwiftUI

struct TypingIndicator: View {
    
    let alignment: Alignment
    let foregroundColor: Color
    let backgroundColor: Color
    
    enum Alignment {
        case leading
        case trailing
    }
    
    init(_ alignment: Alignment, foregroundColor: Color = .secondary, backgroundColor: Color = .secondary.opacity(0.15)) {
        self.alignment = alignment
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            switch alignment {
            case .leading:
                TypingEllipsis(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
                Spacer()
            case .trailing:
                Spacer()
                TypingEllipsis(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
            }
        }
    }
}

// MARK: Private

private struct TypingEllipsis: View {
    let foregroundColor: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<3, id: \.self) { index in
                TypingDot(color: foregroundColor, size: dotSize, delay: Double(index)*0.2)
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

private struct TypingDot: View {
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
