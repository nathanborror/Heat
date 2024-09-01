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
            ContentView(text: tag.content)
        }
        .padding(12)
        .background(.background)
        .clipShape(.rect(cornerRadius: 10))
        .colorInvert()
    }
}
