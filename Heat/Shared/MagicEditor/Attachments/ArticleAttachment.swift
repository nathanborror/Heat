import SwiftUI

class ArticleAttachment: NSTextAttachment, @unchecked Sendable {
    let content: String

    init(content: String) {
        self.content = content
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewProvider(for parentView: PlatformView?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        MagicAttachmentViewProvider(
            content: ArticleAttachmentView(content: content),
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
}

struct ArticleAttachmentView: View {
    var content: String

    var body: some View {
        Text(content)
            .font(.system(size: 15))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.primary.opacity(0.05))
            )
    }
}
