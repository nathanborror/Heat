import SwiftUI
import MarkdownUI

struct CodeBlockView: View {
    let configuration: CodeBlockConfiguration

    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(configuration.language?.capitalized ?? "")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Button(action: copyCodeAction) {
                    Image(systemName: isCopied ? "checkmark" : "square.on.square")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(.secondary)
            .colorInvert()
            
            Divider()
                .colorInvert()
            
            configuration.label
                .relativeLineSpacing(.em(0.25))
                .padding(12)
        }
        .background(.primary)
        .clipShape(.rect(cornerRadius: 5))
        .padding(.horizontal, -12)
    }
    
    private func copyCodeAction() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(configuration.content, forType: .string)
        #else
        let pasteboard = UIPasteboard.general
        pasteboard.string = configuration.content
        #endif
        
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}

extension CodeBlockConfiguration: @retroactive Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(language)
        hasher.combine(content)
    }
    
    public static func == (lhs: CodeBlockConfiguration, rhs: CodeBlockConfiguration) -> Bool {
        return lhs.language == rhs.language && lhs.content == rhs.content
    }
}
