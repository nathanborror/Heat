import SwiftUI
import GenKit
import HeatKit

struct RenderOutput: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RenderText(tag.content, tags: ["reflection", "image_search_query"])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
