import SwiftUI
import MarkdownUI

struct ContentView: View {
    @Environment(\.textRendering) private var textRendering
    
    let text: String?
    
    var body: some View {
        switch textRendering {
        case .markdown:
            Markdown(text ?? "")
                .markdownTheme(.app)
                .markdownCodeSyntaxHighlighter(.app)
                .textSelection(.enabled)
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
