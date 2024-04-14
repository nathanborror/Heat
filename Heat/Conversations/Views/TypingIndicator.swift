import SwiftUI

struct TypingIndicator: View {
    let foregroundColor: Color
    
    @State private var isVisible = true
    
    init(foregroundColor: Color = .primary) {
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Rectangle()
                .fill(foregroundColor)
                .frame(width: cursorWidth, height: cursorHeight)
                .clipShape(.rect(cornerRadius: 2))
                .opacity(isVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            handleBlink()
        }
    }
    
    func handleBlink() {
        withAnimation(.snappy(duration: 0.4).repeatForever(autoreverses: true)) {
            isVisible.toggle()
        }
    }
    
    #if os(macOS)
    private let cursorWidth: CGFloat = 2
    private let cursorHeight: CGFloat = 16
    #else
    private let cursorWidth: CGFloat = 2
    private let cursorHeight: CGFloat = 20
    #endif
}
