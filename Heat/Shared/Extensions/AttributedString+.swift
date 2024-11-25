import SwiftUI

extension AttributedString {

    init(markdown: String) throws {
        var s = try AttributedString(
            markdown: markdown,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible,
                languageCode: "en"
            ),
            baseURL: nil
        )

        // Base font and paragraph style for the whole string
        s.font = .body
        s.mergeAttributes(.init([.paragraphStyle: ParagraphStyle.default]))
        s.foregroundColor = .primary // Respect dark mode automatically

        // Inline elements
        let inlineIntents: [InlinePresentationIntent] = [
            .emphasized,
            .stronglyEmphasized,
            .code,
            .strikethrough,
            .softBreak,
            .lineBreak,
            .inlineHTML,
            .blockHTML
        ]

        for inlineIntent in inlineIntents {
            var sourceAttributeContainer = AttributeContainer()
            sourceAttributeContainer.inlinePresentationIntent = inlineIntent

            var targetAttributeContainer = AttributeContainer()
            switch inlineIntent {
            case .emphasized:
                targetAttributeContainer.font = .body.italic()
            case .stronglyEmphasized:
                targetAttributeContainer.font = .body.weight(.semibold)
            case .code:
                targetAttributeContainer.font = .system(.body, design: .monospaced)
            case .strikethrough:
                targetAttributeContainer.strikethroughStyle = .single
            case .softBreak:
                break // TODO: Implement
            case .lineBreak:
                break // TODO: Implement
            case .inlineHTML:
                break // TODO: Implement
            case .blockHTML:
                break // TODO: Implement
            default:
                break
            }
            s = s.replacingAttributes(sourceAttributeContainer, with: targetAttributeContainer)
        }

        // Block elements
        var previousListID = 0
        for (intentBlock, intentRange) in s.runs[\.presentationIntent].reversed() {
            guard let intentBlock = intentBlock else { continue }

            var block: MarkdownStyledBlock = .generic
            var currentElementOrdinal: Int = 0

            var currentListID = 0

            for intent in intentBlock.components {
                switch intent.kind {
                case .paragraph:
                    if block == .generic {
                        block = .paragraph
                    }
                case .header(level: let level):
                    block = .headline(level)
                case .orderedList:
                    block = .orderedListElement(currentElementOrdinal)
                    currentListID = intent.identity
                case .unorderedList:
                    block = .unorderedListElement
                    currentListID = intent.identity
                case .listItem(ordinal: let ordinal):
                    currentElementOrdinal = ordinal
                    if block != .unorderedListElement {
                        block = .orderedListElement(ordinal)
                    }
                case .codeBlock(languageHint: let languageHint):
                    block = .code(languageHint)
                case .blockQuote:
                    block = .blockquote
                case .thematicBreak:
                    break
                case .table(columns: _):
                    break
                case .tableHeaderRow:
                    break
                case .tableRow(rowIndex: _):
                    break
                case .tableCell(columnIndex: _):
                    break
                @unknown default:
                    break
                }
            }

            var numberBreaks = 0

            switch block {
            case .generic:
                assertionFailure(intentBlock.debugDescription)
            case .headline(let level):
                switch level {
                case 1:
                    s[intentRange].font = .title.weight(.bold)
                case 2:
                    s[intentRange].font = .title2.weight(.semibold)
                default:
                    s[intentRange].font = .title3.weight(.medium)
                }
                numberBreaks = 2
            case .paragraph:
                numberBreaks = 2
            case .unorderedListElement:
                s.characters.insert(contentsOf: "•\t", at: intentRange.lowerBound)
                let style = (previousListID == currentListID) ? ParagraphStyle.list : ParagraphStyle.listLastElement
                s[intentRange].mergeAttributes(.init([.paragraphStyle: style]))
                numberBreaks = 1
            case .orderedListElement(let ordinal):
                s.characters.insert(contentsOf: "\(ordinal).\t", at: intentRange.lowerBound)
                let style = (previousListID == currentListID) ? ParagraphStyle.list : ParagraphStyle.listLastElement
                s[intentRange].mergeAttributes(.init([.paragraphStyle: style]))
                numberBreaks = 1
            case .blockquote:
                s[intentRange].mergeAttributes(.init([.paragraphStyle: ParagraphStyle.default]))
                s[intentRange].foregroundColor = .secondary
                numberBreaks = 2
            case .code:
                s[intentRange].font = .system(.body, design: .monospaced)
                s[intentRange].foregroundColor = .white
                s[intentRange].backgroundColor = .black
                s[intentRange].mergeAttributes(.init([.paragraphStyle: ParagraphStyle.code]))
                numberBreaks = 2
            }

            // Remember the list ID so we can check if it’s identical in the next block
            previousListID = currentListID

            // Add line breaks to separate blocks
            if intentRange.lowerBound != s.startIndex {
                let breaks = String(repeating: "\n", count: numberBreaks)
                s.characters.insert(contentsOf: breaks, at: intentRange.lowerBound)
            }
        }

        self = s
    }
}

private enum MarkdownStyledBlock: Equatable {
    case generic
    case headline(Int)
    case paragraph
    case unorderedListElement
    case orderedListElement(Int)
    case blockquote
    case code(String?)
}

struct ParagraphStyle {

    nonisolated(unsafe) static let `default`: NSParagraphStyle = {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 10.0
        paragraphStyle.minimumLineHeight = 20.0
        return paragraphStyle
    }()

    nonisolated(unsafe) static let list: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        paragraphStyle.headIndent = 20
        paragraphStyle.minimumLineHeight = 20.0
        return paragraphStyle
    }()

    nonisolated(unsafe) static let listLastElement: NSParagraphStyle = {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        paragraphStyle.headIndent = 20
        paragraphStyle.minimumLineHeight = 20.0
        paragraphStyle.paragraphSpacing = 20.0 // The last element in a list needs extra paragraph spacing
        return paragraphStyle
    }()

    nonisolated(unsafe) static let code: NSParagraphStyle = {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 20.0
        paragraphStyle.firstLineHeadIndent = 12
        paragraphStyle.headIndent = 12
        return paragraphStyle
    }()
}
