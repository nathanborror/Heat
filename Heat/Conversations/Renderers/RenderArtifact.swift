import SwiftUI
import GenKit
import HeatKit

struct RenderArtifact: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                RenderText(tag.content, tags: ["image_search_query"])
            }
            .padding(24)
            .frame(maxWidth: 700)
            .background {
                Rectangle()
                    .fill(.background)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    .shadow(color: .primary.opacity(0.1), radius: 20, y: 10)
            }
        }
    }
}
