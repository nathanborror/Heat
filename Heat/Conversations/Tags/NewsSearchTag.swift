import SwiftUI
import GenKit
import HeatKit

struct NewsSearchTag: View {
    let tag: ContentParser.Result.Tag
    
    init(_ tag: ContentParser.Result.Tag) {
        self.tag = tag
    }
    
    var body: some View {
        Text("<\(tag.name)> not implemented")
    }
}
