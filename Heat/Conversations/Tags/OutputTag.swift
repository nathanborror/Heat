import SwiftUI
import GenKit
import HeatKit

struct OutputTag: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        let tags = ["reflection", "image_search_query"]
        guard let results = try? parser.parse(input: content, tags: tags) else { return [] }
        return results.contents
    }
    
    private let parser = ContentParser.shared
}
