import SwiftUI

/// A generic attachment view provider that should be used with custom `NSTextAttachment` instances.
class MagicAttachmentViewProvider<Content: View>: NSTextAttachmentViewProvider {

    private let content: Content
    private var measuredSize: CGSize = .zero

    init(content: Content, textAttachment: NSTextAttachment, parentView: PlatformView?, textLayoutManager: NSTextLayoutManager?, location: any NSTextLocation) {
        self.content = content
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
        tracksTextAttachmentViewBounds = true
    }

    override func loadView() {
        let attachmentView = MagicAttachmentView(content: content)
        attachmentView.frame = CGRect(origin: .zero, size: measuredSize)
        self.view = attachmentView
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key : Any], location: any NSTextLocation,
                                   textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        let measuringView = MagicAttachmentView(content: content)
        let fittingSize = measuringView.fittingSize(for: proposedLineFragment.width)

        measuredSize = fittingSize
        return CGRect(origin: .zero, size: measuredSize)
    }
}

/// A generic attachment view that should only be used by `MagicAttachmentViewProvider` when loading custom `NSTextAttachment` views.
fileprivate class MagicAttachmentView<Content: View>: PlatformView {

    var attachment: NSTextAttachment? {
        didSet { updateHostingView() }
    }

    private var content: Content
    private var hostingController: PlatformHostingController<Content>?

    init(content: Content) {
        self.content = content
        super.init(frame: .zero)

        #if os(macOS)
        wantsLayer = true
        layer?.backgroundColor = .clear
        #endif
        
        updateHostingView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateHostingView() {
        hostingController?.view.removeFromSuperview()
        hostingController = PlatformHostingController(rootView: content)

        guard let hostingView = hostingController?.view else { return }

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: PlatformSize {
        return hostingController?.view.intrinsicContentSize ?? .zero
    }

    func fittingSize(for width: CGFloat) -> CGSize {
        guard let hostingController else { return .zero }
        let targetSize = PlatformSize(width: width, height: .greatestFiniteMagnitude)
        return hostingController.sizeThatFits(in: targetSize)
    }
}
