import SwiftUI
import GenKit
import HeatKit

struct RenderThinking: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Thinking".uppercased())
                .font(.footnote.bold())
                .foregroundStyle(.primary.opacity(0.5))
            RenderText(tag.content, tags: ["reflection"])
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 10))
        .colorInvert()
    }
}
