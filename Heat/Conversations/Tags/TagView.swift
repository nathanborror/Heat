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
        case "reflection":
            ReflectionTag(tag: tag)
        case "output":
            ContentView(tag.content)
                .padding(.leading, 12)
        case "image_search_query":
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
