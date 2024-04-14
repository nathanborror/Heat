import SwiftUI
import HeatKit

struct SuggestionList<Content: View>: View {
    var suggestions: [String]
    var content: (String) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(suggestions, id: \.self) { suggestion in
                content(suggestion)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.tint.opacity(0.05))
                .foregroundStyle(.tint)
                .clipShape(.rect(cornerRadius: 10))
                .padding(.leading, -12)
        }
        .buttonStyle(.plain)
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
