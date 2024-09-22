import SwiftUI
import MarkdownUI
import GenKit

struct ContentView: View {
    @Environment(\.textRendering) private var textRendering
    
    let text: String?
    let role: Message.Role
    
    var body: some View {
        switch textRendering {
        case .markdown:
            if role == .user {
                Markdown(text ?? "")
                    .markdownTheme(.app)
                    .markdownCodeSyntaxHighlighter(.app)
                    .markdownTextStyle {
                        ForegroundColor(.white)
                    }
                    .textSelection(.enabled)
            } else {
                Markdown(text ?? "")
                    .markdownTheme(.app)
                    .markdownCodeSyntaxHighlighter(.app)
                    .textSelection(.enabled)
            }
        case .attributed:
            Text(toAttributedString)
                .textSelection(.enabled)
        case .text:
            Text(text ?? "")
                .textSelection(.enabled)
        }
    }
    
    var toAttributedString: AttributedString {
        try! .init(markdown: text ?? "")
    }
}
