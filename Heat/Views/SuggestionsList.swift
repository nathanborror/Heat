import SwiftUI
import HeatKit

struct SuggestionList<Content: View>: View {
    var suggestions: [String]
    var content: (String) -> Content
    
    var body: some View {
        VStack(spacing: 4) {
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
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.borderless)
        .background(colorScheme == .light ? Color.accentColor.opacity(0.1) : .secondary.opacity(0.2))
        .tint(colorScheme == .light ? .accentColor : .white.opacity(0.65))
        .clipShape(.rect(cornerRadius: 10))
    }
    
    func handleTap(_ text: String) {
        action(suggestion)
    }
}
