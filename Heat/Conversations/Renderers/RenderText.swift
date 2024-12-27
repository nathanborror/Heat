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
        VStack(alignment: .leading, spacing: 6) {
            ForEach(toTaggedContents.indices, id: \.self) { index in
                switch toTaggedContents[index] {
                case let .text(text):
                    switch state.textRendering {
                    case .markdown:
                        Markdown(text)
                            .markdownCodeSyntaxHighlighter(.app)
                    case .attributed:
                        Text(toAttributedString)
                    default:
                        Text(text)
                    }
                case let .tag(tag):
                    RenderTag(tag)
                }
            }
        }
        .textSelection(.enabled)
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
        case .assistant:
            switch state.textRendering {
            case .markdown:
                content
                    .markdownTheme(.assistant)
            case .attributed:
                content
            case .text:
                content
            }
        case .user:
            HStack {
                Spacer()
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
