import UIKit

class MagicEditorViewController: UIViewController {
    typealias Callback = () -> Void

    var onSubmit: Callback?
    var onMenuShow: ((CGPoint) -> Void)?
    var onMenuHide: Callback?
    var onMenuUp: Callback?
    var onMenuDown: Callback?
    var onMenuSelect: Callback?

    lazy var textView: UITextView = {
        let textLayoutManager = NSTextLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textLayoutManager.textContainer = textContainer

        let textContentStorage = NSTextContentStorage()
        textContentStorage.delegate = self
        textContentStorage.addTextLayoutManager(textLayoutManager)

        let textView = UITextView(frame: view.bounds, textContainer: textContainer)
        textView.delegate = self
        textView.textLayoutManager?.delegate = self
        textView.textStorage.delegate = self
        textView.textContainerInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setAttributedString(_ attributedString: NSAttributedString, force: Bool = false) {
        if textView.textStorage.isEqual(to: attributedString) == false || force {
            textView.textStorage.setAttributedString(attributedString)
        }
    }
}

extension MagicEditorViewController: NSTextStorageDelegate {

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }

        // Check if the last character entered was "/"
        if delta > 0 && editedRange.location + editedRange.length <= textStorage.string.count {
            let nsString = textStorage.string as NSString
            if editedRange.location + editedRange.length > 0 &&
               nsString.substring(with: NSRange(location: editedRange.location + editedRange.length - 1, length: 1)) == "/" {

                // Use DispatchQueue.main.async to ensure the text editing operation is complete
                DispatchQueue.main.async { [weak self] in
                    if let point = self?.textView.cursorPosition() {
                        self?.onMenuShow?(CGPoint(x: point.x, y: point.y))
                    }
                }
            }
        }
    }
}

extension MagicEditorViewController: NSTextContentManagerDelegate {

    // This is where attributes can be shown or hidden. They are all shown by default.
    func textContentManager(_ textContentManager: NSTextContentManager, shouldEnumerate textElement: NSTextElement, options: NSTextContentManager.EnumerationOptions = []) -> Bool {
        return true
    }
}

extension MagicEditorViewController: NSTextContentStorageDelegate {

    // This is where attributes can be located and modified. This will only affect the attributed string
    // attributes for the attributes (e.g. font, foreground color, etc)
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        let original = textContentStorage.textStorage!.attributedSubstring(from: range)

        // Decorate custom attributes
        if original.attribute(.roleAttribute, at: 0, effectiveRange: nil) != nil {
            let attributes: [NSAttributedString.Key: AnyObject] = [.foregroundColor: UIColor.systemRed]
            let attributedString = NSMutableAttributedString(attributedString: original)
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.addAttributes(attributes, range: range)
            return NSTextParagraph(attributedString: attributedString)
        }

        return nil
    }
}

extension MagicEditorViewController: NSTextLayoutManagerDelegate {

    // This is where attributes can receive a custom layout (e.g. custom view) — I think this view is just
    // applied as a background to the attributed string. Throws an exception if the location is outside the bounds
    // of the length, also when location and length are 0.
    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        let ignore = NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        let location = textLayoutManager.offset(from: textLayoutManager.documentRange.location, to: location)

        let length = textView.textStorage.length
        guard location < length else {
            return ignore
        }

        // Decorate layout of custom attributes
        if textView.textStorage.attribute(.roleAttribute, at: location, effectiveRange: nil) as? NSNumber != nil {
            return RoleFragment(textElement: textElement, range: textElement.elementRange)
        }

        return ignore
    }
}

extension MagicEditorViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, doCommandBy commandSelector: Selector) -> Bool {

        // Check for backspace key when menu is showing
        if commandSelector == #selector(UIResponder.delete(_:)) {
            if textView.hasSlashBeforeCursor {
                onMenuHide?()
                return false
            }
        }

        return false
    }
}

extension UITextView {

    var hasSlashBeforeCursor: Bool {
        let cursorLocation = selectedRange.location
        guard cursorLocation > 0 else { return false }
        let range = NSRange(location: cursorLocation-1, length: 1)
        let characterBeforeCursor = textStorage.attributedSubstring(from: range)
        return characterBeforeCursor.string == "/"
    }

    func cursorPosition() -> CGPoint? {
        guard let selectedRange = selectedTextRange else { return nil }
        let endPosition = selectedRange.end
        let caretRect = caretRect(for: endPosition)
        return caretRect.origin
    }
}
