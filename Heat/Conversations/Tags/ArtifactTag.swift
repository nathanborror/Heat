import SwiftUI
import GenKit
import HeatKit

struct ArtifactTag: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(24)
        .background {
            Rectangle()
                .fill(.background)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .shadow(color: .primary.opacity(0.1), radius: 20, y: 10)
        }
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        let results = try? parser.parse(input: content, tags: ["image_search_query", "news_search"])
        return results?.contents ?? []
    }
    
    private let parser = ContentParser.shared
}
