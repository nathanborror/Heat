import SwiftUI
import GenKit
import HeatKit

struct TagView: View {
    let tag: ContentParser.Result.Tag
    
    var body: some View {
        switch tag.name {
        case "artifact":
            ArtifactTag(tag: tag)
        case "thinking":
            ThinkingTag(tag: tag)
        case "image_search":
            ImageSearchTag(tag: tag)
        case "news_search":
            NewsSearchTag(tag: tag)
        default:
            Text("<\(tag.name)> not implemented")
        }
    }
}

enum TagViewError: Error {
    case missingContent
}
