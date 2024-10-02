import SwiftUI
import GenKit
import HeatKit

struct ThinkingTag: View {
    let tag: ContentParser.Result.Tag

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Thinking")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            Divider()
                .opacity(0.5)
            
            Group {
                ForEach(contents.indices, id: \.self) { index in
                    switch contents[index] {
                    case .text(let text):
                        ContentView(text)
                    case .tag(let tag):
                        TagView(tag: tag)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 10))
    }
    
    var contents: [ContentParser.Result.Content] {
        guard let content = tag.content else { return [] }
        guard let results = try? parser.parse(input: content, tags: ["reflection"]) else { return [] }
        return results.contents
    }
    
    private let parser = ContentParser.shared
}
