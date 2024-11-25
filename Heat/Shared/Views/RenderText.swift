import SwiftUI
import MarkdownUI
import GenKit
import HeatKit

struct RenderText: View {
    @Environment(AppState.self) var state

    let text: String?
    let role: Message.Role

    init(_ text: String?, role: Message.Role = .assistant) {
        self.text = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.role = role
    }

    var body: some View {
        switch state.textRendering {
        case .markdown:
            if role == .user {
                Markdown(text ?? "")
                    .markdownTheme(.user)
                    .markdownCodeSyntaxHighlighter(.app)
                    .textSelection(.enabled)
            } else {
                Markdown(text ?? "")
                    .markdownTheme(.assistant)
                    .markdownCodeSyntaxHighlighter(.app)
                    .textSelection(.enabled)
            }
        case .attributed:
            if role == .user {
                Text(toAttributedString)
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
            } else {
                Text(toAttributedString)
                    .textSelection(.enabled)
            }
        default:
            if role == .user {
                Text(text ?? "")
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
            } else {
                Text(text ?? "")
                    .textSelection(.enabled)
            }
        }
    }

    var toAttributedString: AttributedString {
        try! .init(markdown: text ?? "")
    }
}
