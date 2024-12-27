import SwiftUI
import MarkdownUI
import GenKit
import HeatKit

struct RenderText: View {
    @Environment(AppState.self) var state

    let text: String
    let tags: [String]

    init(_ text: String?, tags: [String] = []) {
        self.text = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.tags = tags
    }

    var body: some View {
        ForEach(toTaggedContents.indices, id: \.self) { index in
            switch toTaggedContents[index] {
            case let .text(text):
                switch state.textRendering {
                case .markdown:
                    Markdown(text)
                        .markdownCodeSyntaxHighlighter(.app)
                        .textSelection(.enabled)
                case .attributed:
                    Text(toAttributedString)
                        .textSelection(.enabled)
                default:
                    Text(text)
                        .textSelection(.enabled)
                }
            case let .tag(tag):
                RenderTag(tag)
            }
        }
    }

    var toAttributedString: AttributedString {
        try! .init(markdown: text)
    }

    var toTaggedContents: [ContentParser.Result.Content] {
        guard let results = try? parser.parse(input: text, tags: tags) else { return [] }
        return results.contents
    }

    private let parser = ContentParser.shared
}

struct RenderModifier: ViewModifier {
    @Environment(AppState.self) var state

    let role: Message.Role

    func body(content: Content) -> some View {
        switch role {
        case .system:
            content
                .padding(.horizontal, 12)
        case .assistant:
            switch state.textRendering {
            case .markdown:
                content
                    .markdownTheme(.assistant)
                    .padding(.horizontal, 12)
            case .attributed:
                content
                    .padding(.horizontal, 12)
            case .text:
                content
                    .padding(.horizontal, 12)
            }
        case .user:
            switch state.textRendering {
            case .markdown:
                content
                    .markdownTheme(.user)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint, in: .rect(cornerRadius: 10))
            case .attributed:
                content
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint, in: .rect(cornerRadius: 10))
            case .text:
                content
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.tint, in: .rect(cornerRadius: 10))
            }
        case .tool:
            content
        }
    }
}

extension View {
    func render(role: Message.Role) -> some View {
        self.modifier(RenderModifier(role: role))
    }
}
