import SwiftUI
import GenKit
import HeatKit

struct RenderTag: View {
    let tag: ContentParser.Result.Tag

    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }

    var body: some View {
        switch tag.name {
        case "artifact":
            RenderArtifact(tag)
        case "thinking":
            RenderThinking(tag)
        case "reflection":
            RenderReflection(tag)
        case "output":
            RenderOutput(tag)
                .padding(.leading, 12)
        case "image_search_query":
            RenderImageSearch(tag)
        default:
            RenderAnyTag(tag)
        }
    }
}

enum TagViewError: Error {
    case missingContent
}
