import SwiftUI
import Splash
import MarkdownUI

struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme

    init(theme: Splash.Theme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        Builder(theme: self.theme)
    }
}

extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text]

        fileprivate init(theme: Splash.Theme) {
            self.theme = theme
            self.accumulatedText = []
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
            #if os(macOS)
            self.accumulatedText.append(Text(token).foregroundStyle(Color(nsColor: color)))
            #else
            self.accumulatedText.append(Text(token).foregroundStyle(Color(uiColor: color)))
            #endif
        }

        mutating func addPlainText(_ text: String) {
            self.accumulatedText.append(
                Text(text).foregroundStyle(plainTextColor)
            )
        }

        mutating func addWhitespace(_ whitespace: String) {
            self.accumulatedText.append(Text(whitespace))
        }

        func build() -> Text {
            self.accumulatedText.reduce(Text(""), +)
        }
        
        private var plainTextColor: SwiftUI.Color {
            #if os(macOS)
            Color(nsColor: self.theme.plainTextColor)
            #else
            Color(uiColor: self.theme.plainTextColor)
            #endif
        }
    }
}

// MARK: - Splash Highlighter

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>

    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        guard language?.lowercased() == "swift" else {
            return Text(content)
        }
        return self.syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}
