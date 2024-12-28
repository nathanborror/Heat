import SwiftUI
import HeatKit

struct SuggestionList<Content: View>: View {
    var suggestions: [String]
    var content: (String) -> Content

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(suggestions, id: \.self) { suggestion in
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
        Button(action: { handleTap(suggestion) }) {
            HStack {
                Spacer()
                Text(suggestion)
                    .font(.system(size: fontSize))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint.opacity(0.05), in: .rect(cornerRadius: 10))
                    .foregroundStyle(.tint)
                    .overlay {
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 10)
                                .inset(by: 1)
                                .stroke(.tint.opacity(0.5), lineWidth: 1)
                        }
                    }
            }
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
    private let fontSize: CGFloat = 16
    #endif
}
