import SwiftUI

extension NSAttributedString.Key {
    public static var roleAttribute: NSAttributedString.Key {
        .init("RoleAttribute")
    }
}

class RoleFragment: NSTextLayoutFragment {

    override var leadingPadding: CGFloat { 12 }
    override var trailingPadding: CGFloat { 0 }
    override var topMargin: CGFloat { 8 }
    override var bottomMargin: CGFloat { 8 }

    override func draw(at point: CGPoint, in context: CGContext) {
        context.saveGState()

        let path = createFragmentPath(with: context)
        context.addPath(path)
        context.setFillColor(.init(gray: 0.9, alpha: 1))
        context.fillPath()
        context.restoreGState()

        super.draw(at: point, in: context)
    }

    override var renderingSurfaceBounds: CGRect {
        fragmentRect.union(super.renderingSurfaceBounds)
    }

    private func createFragmentPath(with context: CGContext) -> CGPath {
        let rect = min(4, fragmentRect.size.height / 2, fragmentRect.size.width / 2)
        return CGPath(roundedRect: fragmentRect, cornerWidth: rect, cornerHeight: rect, transform: nil)
    }

    private var fragmentRect: CGRect { return tightTextBounds.insetBy(dx: -12, dy: -4) }

    private var tightTextBounds: CGRect {
        var fragmentTextBounds = CGRect.null
        for lineFragment in textLineFragments {
            let lineFragmentBounds = lineFragment.typographicBounds
            if fragmentTextBounds.isNull {
                fragmentTextBounds = lineFragmentBounds
            } else {
                fragmentTextBounds = fragmentTextBounds.union(lineFragmentBounds)
            }
        }
        return fragmentTextBounds
    }
}
