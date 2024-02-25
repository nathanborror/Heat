import SwiftUI
import MarkdownUI

extension MarkdownUI.Theme {
    
    static let mate = MarkdownUI.Theme()
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(12)
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(12)
                }
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(monospaceFontSize)
                    FontFamily(.system(.monospaced))
                }
        }
    
    #if os(macOS)
    static let monospaceFontSize: CGFloat = 11
    #else
    static let monospaceFontSize: CGFloat = 14
    #endif
}
