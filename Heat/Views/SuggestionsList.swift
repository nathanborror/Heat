import SwiftUI
import HeatKit

struct SuggestionList<Content: View>: View {
    var suggestions: [String]
    var content: (String) -> Content
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(suggestions, id: \.self) { suggestion in
                HStack {
                    Spacer()
                    content(suggestion)
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
        ZStack(alignment: .bottomTrailing) {
            Button(action: { handleTap(suggestion) }) {
                Text(suggestion)
                    .multilineTextAlignment(.leading)
                    #if os(iOS)
                    .padding(.vertical, 10)
                    #endif
            }
            #if os(iOS)
            .buttonStyle(.borderless)
            #endif
        }
        #if os(iOS)
        .padding(.horizontal)
        .background(colorScheme == .light ? Color.accentColor.opacity(0.1) : .secondary.opacity(0.2))
        .tint(colorScheme == .light ? .accentColor : .white.opacity(0.65))
        .clipShape(.rect(cornerRadius: 22))
        #endif
    }
    
    func handleTap(_ text: String) {
        action(suggestion)
    }
}
