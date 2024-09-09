import SwiftUI
import GenKit
import HeatKit

struct ThinkingTag: View {
    let tag: ContentParser.Result.Tag

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Thinking".uppercased())
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
        .padding(12)
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
