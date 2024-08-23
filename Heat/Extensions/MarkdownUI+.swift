import SwiftUI
@preconcurrency import MarkdownUI

extension MarkdownUI.Theme {
    
    static let mate = MarkdownUI.Theme()
        .paragraph { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                }
                .lineSpacing(lineSpacing)
        }
        .heading1 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.bold)
                }
                .lineSpacing(lineSpacing)
        }
        .heading2 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.semibold)
                }
                .lineSpacing(lineSpacing)
        }
        .heading3 { config in
            config.label
                .markdownTextStyle {
                    FontSize(fontSize)
                    FontWeight(.medium)
                }
                .lineSpacing(lineSpacing)
        }
        .codeBlock { config in
            ZStack(alignment: .topTrailing) {
                config.label
                    .markdownTextStyle {
                        FontSize(monospacedSize)
                        FontFamilyVariant(.monospaced)
                    }
                    .lineSpacing(lineSpacing)
                    .padding(.horizontal, paddingHorizontal)
                    .padding(.vertical, paddingVertical)
                    .padding(.trailing, 16)
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: cornerRadius))
                
                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = config.content
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(config.content, forType: .string)
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.small)
                        .padding(5)
                }
                .foregroundStyle(.primary.opacity(0.3))
                .buttonStyle(.plain)
            }
        }
    
    #if os(macOS)
    static let fontSize: CGFloat = 14
    static let monospacedSize: CGFloat = 12
    static let lineSpacing: CGFloat = 2
    static let cornerRadius: CGFloat = 8
    static let paddingHorizontal: CGFloat = 12
    static let paddingVertical: CGFloat = 6
    #else
    static let fontSize: CGFloat = 17
    static let monospacedSize: CGFloat = 14
    static let lineSpacing: CGFloat = 2
    static let cornerRadius: CGFloat = 10
    static let paddingHorizontal: CGFloat = 16
    static let paddingVertical: CGFloat = 10
    #endif
}
