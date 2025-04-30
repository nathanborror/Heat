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
        case "thinking", "think":
            RenderThinking(tag)
        case "reflection":
            RenderReflection(tag)
        case "output", "summary":
            RenderOutput(tag)
        case "image_search_query":
            RenderImageSearch(tag)
        default:
            RenderAnyTag(tag)
        }
    }
}

enum RenderTagError: Error {
    case missingContent
}
