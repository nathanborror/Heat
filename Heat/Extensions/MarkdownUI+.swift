import SwiftUI
import MarkdownUI
import HeatKit

class ThemeCache {
    static let shared = ThemeCache()
    
    private var cachedTheme: Theme?
    private var cachedCodeBlocks: [CodeBlockConfiguration: CodeBlockView] = [:]
    
    func getTheme() -> Theme {
        #if os(macOS)
        let margin: RelativeSize = .em(1)
        let fontSize: CGFloat = 14
        let relativeLineSpacing: RelativeSize = .em(0.25)
        let listItemMargin: RelativeSize = .em(0.25)
        #else
        let margin: RelativeSize = .em(1)
        let fontSize: CGFloat = 16
        let relativeLineSpacing: RelativeSize = .em(0.25)
        let listItemMargin: RelativeSize = .em(0.25)
        #endif
        
        if let existingTheme = cachedTheme {
            return existingTheme
        } else {
            let newTheme = Theme()
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
                .codeBlock { [weak self] configuration in
                    self?.getCodeBlockView(for: configuration) ?? CodeBlockView(configuration: configuration)
                }
            
            cachedTheme = newTheme
            
            return newTheme
        }
    }
    
    private func getCodeBlockView(for configuration: CodeBlockConfiguration) -> CodeBlockView {
        if let cachedView = cachedCodeBlocks[configuration] {
            return cachedView
        } else {
            let newView = CodeBlockView(configuration: configuration)
            cachedCodeBlocks[configuration] = newView
            
            return newView
        }
    }
}

extension Theme {
    static var app: Theme {
        ThemeCache.shared.getTheme()
    }
}
