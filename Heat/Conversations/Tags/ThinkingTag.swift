import SwiftUI
import GenKit
import HeatKit

struct ThinkingTag: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Thinking".uppercased())
                .font(.footnote.bold())
                .foregroundStyle(.primary.opacity(0.5))
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
        .background(.background, in: .rect(cornerRadius: 10))
        .colorInvert()
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        guard let results = try? parser.parse(input: content, tags: ["reflection"]) else { return [] }
        return results.contents
    }
    
    private let parser = ContentParser.shared
}
