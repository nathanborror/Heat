import SwiftUI

class RoleAttachment: NSTextAttachment, @unchecked Sendable {
    let role: String

    init(role: String) {
        self.role = role
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewProvider(for parentView: PlatformView?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        MagicAttachmentViewProvider(
            content: RoleAttachmentView(role: role),
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
}

struct RoleAttachmentView: View {
    var role: String

    private let attachmentFontSize: CGFloat = 13
    private let attachmentHorizontalPadding: CGFloat = 8
    private let attachmentVerticalPadding: CGFloat = 3
    private let attachmentCornerRadius: CGFloat = 10

    private var attachmentTextColor: Color {
        switch role {
        case "assistant": .blue
        case "system": .pink
        case "user": .green
        default: .primary
        }
    }

    private var attachmentBackgroundColor: Color {
        switch role {
        case "assistant": .blue.opacity(0.2)
        case "system": .pink.opacity(0.2)
        case "user": .green.opacity(0.2)
        default: .primary.opacity(0.2)
        }
    }

    var body: some View {
        Text(role.capitalized)
            .font(.system(size: attachmentFontSize))
            .foregroundColor(attachmentTextColor)
            .padding(.horizontal, attachmentHorizontalPadding)
            .padding(.vertical, attachmentVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: attachmentCornerRadius)
                    .fill(attachmentBackgroundColor)
            )
    }
}
