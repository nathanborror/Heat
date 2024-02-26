import SwiftUI
import HeatKit

struct SuggestionList<Content: View>: View {
    var suggestions: [String]
    var content: (String) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(suggestions, id: \.self) { suggestion in
                HStack {
                    content(suggestion)
                    Spacer()
                }
            }
        }
    }
}

struct SuggestionView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let suggestion: String
    let action: (String) -> Void
    
    var body: some View {
        Button(action: { handleTap(suggestion) }) {
            Text(suggestion)
                .multilineTextAlignment(.leading)
                .font(.system(size: fontSize))
                .lineSpacing(2)
        }
        .buttonStyle(.borderless)
        .tint(colorScheme == .light ? .accentColor : .white.opacity(0.65))
        #if os(macOS)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        #endif
    }
    
    func handleTap(_ text: String) {
        action(suggestion)
    }
    
    #if os(macOS)
    private let fontSize: CGFloat = 14
    #else
    private let fontSize: CGFloat = 17
    #endif
}
