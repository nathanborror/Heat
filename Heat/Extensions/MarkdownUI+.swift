import SwiftUI
import MarkdownUI
import HeatKit

extension Theme {

    #if os(macOS)
    static let margin: RelativeSize = .em(1)
    static let fontSize: CGFloat = 14
    static let relativeLineSpacing: RelativeSize = .em(0.25)
    static let listItemMargin: RelativeSize = .em(0.25)
    #else
    static let margin: RelativeSize = .em(1)
    static let fontSize: CGFloat = 16
    static let relativeLineSpacing: RelativeSize = .em(0.25)
    static let listItemMargin: RelativeSize = .em(0.25)
    #endif

    static let user = assistant
        .text {
            ForegroundColor(.white)
        }
        .link {
            ForegroundColor(.white)
            UnderlineStyle(.single)
        }

    static let assistant = base

    static let base = Theme()
        .text {
            FontSize(fontSize)
        }
        .link {
            ForegroundColor(.primary)
            UnderlineStyle(.single)
        }
        .paragraph { config in
            config.label
                .relativeLineSpacing(relativeLineSpacing)
        }
        .list { config in
            config.label
                .markdownMargin(top: margin, bottom: margin)
        }
        .listItem { config in
            config.label
                .markdownMargin(top: listItemMargin, bottom: listItemMargin)
        }
        .bulletedListMarker { config in
            Circle()
                .fill(.primary.opacity(0.3))
                .frame(width: 4, height: 4)
        }
        .numberedListMarker { config in
            Text("\(config.itemNumber))")
        }
        .heading1 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.bold)
                }
                .relativeLineSpacing(relativeLineSpacing)
        }
        .heading2 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.semibold)
                }
                .relativeLineSpacing(relativeLineSpacing)
        }
        .heading3 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.medium)
                }
                .relativeLineSpacing(relativeLineSpacing)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontWeight(.medium)
        }
        .codeBlock { configuration in
            CodeBlockView(configuration: configuration)
        }
}
