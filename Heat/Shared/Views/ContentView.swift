import SwiftUI
import MarkdownUI
import GenKit
import HeatKit

struct ContentView: View {
    let text: String?
    let role: Message.Role
    let formatter: Preferences.TextRendering!
    
    init(_ text: String?, role: Message.Role = .assistant, formatter: Preferences.TextRendering? = nil) {
        self.text = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.role = role
        self.formatter = formatter ?? PreferencesProvider.shared.preferences.textRendering
    }
    
    var body: some View {
        switch formatter {
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
        default:
            Text(text ?? "")
                .textSelection(.enabled)
        }
    }
    
    var toAttributedString: AttributedString {
        try! .init(markdown: text ?? "")
    }
}
