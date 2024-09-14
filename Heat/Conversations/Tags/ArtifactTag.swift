import SwiftUI
import GenKit
import HeatKit

struct ArtifactTag: View {
    let tag: ContentParser.Result.Tag

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(contents.indices, id: \.self) { index in
                switch contents[index] {
                case .text(let text):
                    ContentView(text: text)
                case .tag(let tag):
                    TagView(tag: tag)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background {
            Rectangle()
                .fill(.background)
                .stroke(Color.primary, lineWidth: 1)
        }
        .padding(.vertical, 12)
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        let results = try? parser.parse(input: content, tags: ["image_search", "news_search"])
        return results?.contents ?? []
    }
    
    private let parser = ContentParser.shared
}
