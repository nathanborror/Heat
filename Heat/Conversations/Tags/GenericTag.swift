import SwiftUI
import GenKit
import HeatKit

struct GenericTag: View {
    let tag: ContentParser.Result.Tag

    @State private var isCopied = false
    
    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(tag.name.uppercased())
                    .font(.footnote.bold())
                    .foregroundStyle(.primary.opacity(0.5))
                Spacer()
                Button {
                    handleCopy()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "square.on.square")
                        .imageScale(.small)
                }
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)
            
            ForEach(contents.indices, id: \.self) { index in
                switch contents[index] {
                case .text(let text):
                    RenderText(text)
                case .tag(let tag):
                    TagView(tag)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        }
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        let tags = ["reflection", "image_search_query"]
        guard let results = try? parser.parse(input: content, tags: tags) else { return [] }
        return results.contents
    }
    
    private let parser = ContentParser.shared
    
    private func handleCopy() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(tag.content ?? "", forType: .string)
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
