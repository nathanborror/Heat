import SwiftUI
import GenKit
import HeatKit

struct TagView: View {
    let tag: ContentParser.Result.Tag
    
    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        switch tag.name {
        case "artifact":
            ArtifactTag(tag)
        case "thinking":
            ThinkingTag(tag)
        case "reflection":
            ReflectionTag(tag)
        case "output":
            OutputTag(tag)
                .padding(.leading, 12)
        case "image_search_query":
            ImageSearchTag(tag)
        case "news_search":
            NewsSearchTag(tag)
        default:
            Text("<\(tag.name)> not implemented")
        }
    }
}

enum TagViewError: Error {
    case missingContent
}
