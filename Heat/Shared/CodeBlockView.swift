import MarkdownUI
import SwiftUI

struct CodeBlockView: View {
    let configuration: CodeBlockConfiguration

    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(configuration.language?.capitalized ?? "")
                    .font(.subheadline)
                Spacer()
                Button(action: copyCodeAction) {
                    Image(systemName: isCopied ? "checkmark" : "clipboard")
                        .imageScale(.small)
                        .frame(height: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.05))
            .foregroundStyle(.secondary)
            
            configuration.label
                .relativeLineSpacing(.em(0.25))
                .padding(.top, 6)
                .padding(.bottom, 12)
                .padding(.horizontal, 12)
        }
        .background(.primary.opacity(0.05))
        .clipShape(.rect(cornerRadius: 10))
        .padding(.horizontal, -12)
    }
    
    private func copyCodeAction() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(configuration.content, forType: .string)
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
