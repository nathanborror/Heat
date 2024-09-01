import SwiftUI
import MarkdownUI

struct ContentView: View {
    let text: String?
    
    var body: some View {
        Markdown(text ?? "")
            .markdownTheme(.app)
            .markdownCodeSyntaxHighlighter(.app)
    }
}
