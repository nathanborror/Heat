import SwiftUI
import GenKit
import HeatKit

struct RenderThinking: View {
    let tag: ContentParser.Result.Tag

    @State var disclosed = false
    
    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                disclosed.toggle()
            } label: {
                Text("Thinking")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if disclosed {
                RenderText(tag.content, tags: ["reflection"])
            }
        }
    }
}
