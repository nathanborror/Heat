import SwiftUI
import MarkdownUI

extension MarkdownUI.Theme {
    
    static let mate = MarkdownUI.Theme()
        .paragraph { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(fontSize)
                }
                .lineSpacing(lineSpacing)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.bold)
                }
                .lineSpacing(lineSpacing)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.semibold)
                }
                .lineSpacing(lineSpacing)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.medium)
                }
                .lineSpacing(lineSpacing)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(monospacedSize)
                    FontFamilyVariant(.monospaced)
                }
        }
    
    #if os(macOS)
    static private var fontSize: CGFloat = 14
    static private var monospacedSize: CGFloat = 12
    static private var lineSpacing: CGFloat = 2
    #else
    static private var fontSize: CGFloat = 17
    static private var monospacedSize: CGFloat = 14
    static private var lineSpacing: CGFloat = 2
    #endif
}
