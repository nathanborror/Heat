import SwiftUI

struct TypingIndicator: View {
    let foregroundColor: Color
    let backgroundColor: Color
    
    init(_ foregroundColor: Color = .secondary, backgroundColor: Color = .secondary.opacity(0.15)) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "chevron.right")
                .imageScale(.small)
                .opacity(0.3)
            TypingEllipsis(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
                .frame(height: 10)
                .padding(.leading, 3)
            Spacer()
        }
    }
}

// MARK: - Private

private struct TypingEllipsis: View {
    let foregroundColor: Color
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<3, id: \.self) { index in
                TypingDot(color: foregroundColor, size: dotSize, delay: Double(index)*0.2)
            }
        }
    }
    
    private let dotSize: CGFloat = 5
    private let dotSpacing: CGFloat = 2
    private let paddingHorizontal: CGFloat = 13
    private let paddingVertical: CGFloat = 13
    private let cornerRadius: CGFloat = 10
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
