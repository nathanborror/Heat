import Foundation
import MarkdownUI
import SwiftUI

class ThemeCache {
    static let shared = ThemeCache()
    
    private var cachedTheme: Theme?
    private var cachedCodeBlocks: [CodeBlockConfiguration: CodeBlockView] = [:]
    
    #if os(macOS)
    private static let fontSize: CGFloat = 14
    #else
    private static let fontSize: CGFloat = 16
    #endif
    
    func getTheme() -> Theme {
        if let existingTheme = cachedTheme {
            return existingTheme
        } else {
            let newTheme = Theme()
                .text {
                    FontSize(Self.fontSize)
                }
                .paragraph { config in
                    config.label
                        .relativeLineSpacing(.em(0.25))
                }
                .heading1 { config in
                    config.label
                        .markdownTextStyle {
                            FontSize(Self.fontSize)
                            FontWeight(.bold)
                        }
                        .relativeLineSpacing(.em(0.25))
                }
                .heading2 { config in
                    config.label
                        .markdownTextStyle {
                            FontSize(Self.fontSize)
                            FontWeight(.semibold)
                        }
                        .relativeLineSpacing(.em(0.25))
                }
                .heading3 { config in
                    config.label
                        .markdownTextStyle {
                            FontSize(Self.fontSize)
                            FontWeight(.medium)
                        }
                        .relativeLineSpacing(.em(0.25))
                }
                .code {
                    FontSize(12)
                    FontFamilyVariant(.monospaced)
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
