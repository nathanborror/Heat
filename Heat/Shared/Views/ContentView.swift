import SwiftUI
import MarkdownUI

struct ContentView: View {
    @Environment(\.useMarkdown) private var useMarkdown
    
    let text: String?
    
    var body: some View {
        if useMarkdown {
            Markdown(text ?? "")
                .markdownTheme(.app)
                .markdownCodeSyntaxHighlighter(.app)
        } else {
            Text(text ?? "")
        }
    }
}
