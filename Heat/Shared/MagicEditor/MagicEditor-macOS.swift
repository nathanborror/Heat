import AppKit

class MagicEditorViewController: NSViewController {
    typealias Callback = () -> Void

    var onSubmit: Callback?
    var onMenuShow: ((CGPoint) -> Void)?
    var onMenuHide: Callback?
    var onMenuUp: Callback?
    var onMenuDown: Callback?
    var onMenuSelect: Callback?

    lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        return scrollView
    }()

    lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.delegate = self
        textView.textStorage?.delegate = self
        textView.textContentStorage?.delegate = self
        textView.textLayoutManager?.delegate = self
        textView.allowsUndo = true
        textView.textContainerInset = .zero
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        return textView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func setAttributedString(_ attributedString: NSAttributedString, force: Bool = false) {
        if textView.textStorage?.isEqual(to: attributedString) == false || force {
            textView.textStorage?.setAttributedString(attributedString)
        }
    }
}

extension MagicEditorViewController: NSTextStorageDelegate {

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
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
            let attributes: [NSAttributedString.Key: AnyObject] = [.foregroundColor: NSColor.systemRed]
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

        guard let length = textView.textStorage?.length, location < length else {
            return ignore
        }
        guard let textStorage = textView.textContentStorage?.textStorage else {
            return ignore
        }

        // Decorate layout of custom attributes
        if textStorage.attribute(.roleAttribute, at: location, effectiveRange: nil) as? NSNumber != nil {
            return RoleFragment(textElement: textElement, range: textElement.elementRange)
        }

        return ignore
    }
}

extension MagicEditorViewController: NSTextViewDelegate {

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {

        // Check for Cmd+Enter key combination
        if NSEvent.modifierFlags.contains(.command) && NSApp.currentEvent?.keyCode == 0x24 {
            onSubmit?()
            return true
        }

        // Check for backspace key when menu is showing
        if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            if textView.hasSlashBeforeCursor {
                onMenuHide?()
                return false
            }
        }

        // Check for arrow up key when menu is showing
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            if textView.hasSlashBeforeCursor {
                onMenuUp?()
                return true
            }
        }

        // Check for arrow down key when menu is showing
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            if textView.hasSlashBeforeCursor {
                onMenuDown?()
                return true
            }
        }

        // Check for enter key when menu is showing
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if textView.hasSlashBeforeCursor {
                onMenuSelect?()
                return true
            }
        }

        return false
    }
}

extension NSTextView {

    var hasSlashBeforeCursor: Bool {
        let cursorLocation = selectedRange().location
        guard cursorLocation > 0 else { return false }
        let range = NSRange(location: cursorLocation-1, length: 1)
        let characterBeforeCursor = textStorage?.attributedSubstring(from: range)
        return characterBeforeCursor?.string == "/"
    }

    func cursorPosition() -> NSPoint? {
        let selectedRange = selectedRange()
        let rect = firstRect(forCharacterRange: selectedRange, actualRange: nil)

        // Convert from screen coordinates to window coordinates
        let windowRect = window?.convertFromScreen(rect)

        // Convert from window coordinates to text view coordinates
        return convert(windowRect?.origin ?? .zero, from: nil)
    }
}
