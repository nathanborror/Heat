import SwiftUI
import GenKit
import HeatKit

struct ReflectionTag: View {
    let tag: ContentParser.Result.Tag

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reflection".uppercased())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            RenderText(tag.content)
        }
        .padding(12)
        .background(.background)
        .clipShape(.rect(cornerRadius: 5))
        .colorInvert()
    }
}
