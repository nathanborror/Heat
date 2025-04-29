import SwiftUI
import SharedKit
import HeatKit

@MainActor
@Observable
final class MagicEditorManager {

    var showingContextMenu = false
    var contextMenuPosition: CGPoint = .zero
    var contextMenuNotification: MenuNotification? = nil

    weak var controller: MagicEditorViewController? = nil

    var textStorage: NSTextStorage? {
        controller?.textView.textStorage
    }

    var selectedRange: NSRange {
        get {
            #if os(macOS)
            controller?.textView.selectedRange() ?? .init()
            #else
            controller?.textView.selectedRange ?? .init()
            #endif
        }
        set {
            #if os(macOS)
            controller?.textView.setSelectedRange(newValue)
            #else
            controller?.textView.selectedRange = newValue
            #endif
        }
    }

    func connect(to controller: MagicEditorViewController) {
        self.controller = controller
        self.controller?.onSubmit = { [weak self] in
            self?.contextMenuNotification = .init(.submit)
            self?.showingContextMenu = false
            self?.contextMenuPosition = .zero
        }
        self.controller?.onMenuShow = { [weak self] point in
            self?.showingContextMenu = true
            self?.contextMenuPosition = point
        }
        self.controller?.onMenuHide = { [weak self] in
            self?.showingContextMenu = false
            self?.contextMenuPosition = .zero
        }
        self.controller?.onMenuUp = { [weak self] in
            self?.contextMenuNotification = .init(.up)
        }
        self.controller?.onMenuDown = { [weak self] in
            self?.contextMenuNotification = .init(.down)
        }
        self.controller?.onMenuSelect = { [weak self] in
            self?.contextMenuNotification = .init(.select)
            self?.showingContextMenu = false
            self?.contextMenuPosition = .zero
        }
    }

    func read(document: Document) {
        let attributedString = decode(document: document)
        controller?.setAttributedString(attributedString, force: true)
    }

    func read(string: String) {
        let attributedString = NSAttributedString(
            string: string,
            attributes: [.font: PlatformFont.systemFont(ofSize: 16)]
        )
        controller?.setAttributedString(attributedString)
    }

    func insert(text: String) {
        insert(text: text, at: selectedRange.location)
        selectedRange = .init(location: selectedRange.location + text.count, length: 0)
    }

    func insert(text: String, at location: Int) {
        guard let textStorage else { return }
        let attributedString = NSAttributedString(string: text, attributes: [
            .font: PlatformFont.systemFont(ofSize: 16),
        ])
        textStorage.insert(attributedString, at: location)
    }

    func insert(attachment: NSTextAttachment) {
        guard let textStorage else { return }

        let attachmentString = NSAttributedString(attachment: attachment)
        textStorage.insert(attachmentString, at: selectedRange.location)

        selectedRange = .init(location: selectedRange.location + 1, length: 0)
    }

    func backspace() {
        guard let textStorage else { return }
        let cursorLocation = selectedRange.location

        // Make sure there's a character before the cursor
        if cursorLocation > 0 {
            // Calculate the range of the character before the cursor
            let range = NSRange(location: cursorLocation - 1, length: 1)
            textStorage.replaceCharacters(in: range, with: "")
        }
    }

    func encode() throws -> Document {
        guard let textStorage else {
            throw Error.missingTextStorage
        }
        var out = Document()
        let range = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttributes(in: range) { attributes, range, stop in
            let str = textStorage.attributedSubstring(from: range).string

            // Attachment attributes
            if let attachment = attributes[NSAttributedString.Key.attachment] as? RoleAttachment {
                let attr = Document.Attribute(key: "Attachment.Role", value: attachment.role, location: range.location, length: range.length)
                out.attributes.append(attr)
            }
            if let attachment = attributes[NSAttributedString.Key.attachment] as? ArticleAttachment {
                let attr = Document.Attribute(key: "Attachment.Article", value: attachment.content, location: range.location, length: range.length)
                out.attributes.append(attr)
            }

            // Font attributes
            if MagicFunction.hasFontBold(attributes) {
                let attr = Document.Attribute(key: "Font.Bold", value: "", location: range.location, length: range.length)
                out.attributes.append(attr)
            }

            out.text += str
        }
        return out
    }

    func decode(document: Document) -> NSAttributedString {
        let out = NSMutableAttributedString(
            string: document.text,
            attributes: [
                .font: PlatformFont.systemFont(ofSize: 16),
            ]
        )
        for attribute in document.attributes {
            let range = NSMakeRange(attribute.location, attribute.length)
            switch attribute.key {
            case "Attachment.Role":
                let attachment = RoleAttachment(role: attribute.value)
                let attachmentString = NSAttributedString(attachment: attachment)
                out.replaceCharacters(in: range, with: attachmentString)
            case "Attachment.Article":
                let attachment = ArticleAttachment(content: attribute.value)
                let attachmentString = NSAttributedString(attachment: attachment)
                out.replaceCharacters(in: range, with: attachmentString)
            case "Font.Bold":
                out.addAttribute(.font, value: PlatformFont.systemFont(ofSize: 16, weight: .bold), range: range)
            default:
                continue
            }
        }
        return out
    }
}

extension MagicEditorManager {

    func bold() {
        guard let textStorage else { return }
        guard selectedRange.location != textStorage.length else { return }

        var effectiveRange = NSRange(location: 0, length: 0)
        for attribute in textStorage.attributes(at: selectedRange.location, effectiveRange: &effectiveRange) {

            // Ignore attachments, they cannot have text styles applied to them
            if MagicFunction.isAttachment(attribute) {
                return
            }

            if MagicFunction.isFontBold(attribute) {
                textStorage.addAttributes([
                    .font: PlatformFont.systemFont(ofSize: 16)
                ], range: effectiveRange)
            } else {
                textStorage.addAttributes([
                    .font: PlatformFont.systemFont(ofSize: 16, weight: .bold)
                ], range: selectedRange)
            }
        }
    }
}

extension MagicEditorManager {

    struct MenuNotification: Identifiable, Equatable {
        let id: String
        let kind: Kind

        enum Kind {
            case down
            case up
            case select
            case submit
        }

        init(_ kind: Kind) {
            self.id = .id
            self.kind = kind
        }
    }

    enum Error: Swift.Error, CustomStringConvertible {
        case missingTextStorage

        public var description: String {
            switch self {
            case .missingTextStorage:
                "Missing text storage"
            }
        }
    }
}
