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
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .opacity(0.5)
                Text(suggestion)
                    .multilineTextAlignment(.leading)
                    .font(.body)
                    .lineSpacing(2)
            }
        }
        .buttonStyle(.borderless)
        .tint(colorScheme == .light ? .accentColor : .white.opacity(0.65))
    }
    
    func handleTap(_ text: String) {
        action(suggestion)
    }
}
