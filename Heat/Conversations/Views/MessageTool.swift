import SwiftUI
import GenKit
import HeatKit
import MarkdownUI
import Splash

struct MessageTool: View {
    let message: Message
    
    @State private var isShowingContext = false
    
    var body: some View {
        VStack(alignment: .leading) {
            switch message.name {
            case Tool.searchWeb.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.searchCalendar.function.name:
                MessageToolContent(message: message, symbol: "checkmark.circle")
            case Tool.searchFiles.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.generateWebBrowse.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.generateImages.function.name:
                MessageToolContent(message: message, symbol: "checkmark.circle")
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(message.attachments.indices, id: \.self) { index in
                            if case .asset(let asset) = message.attachments[index] {
                                PictureView(asset: asset)
                                    .frame(width: 300, height: 300)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                        }
                        Spacer()
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            case Tool.generateMemory.function.name:
                MessageToolContent(message: message, symbol: "checkmark.circle")
            default:
                MessageToolContent(message: message, symbol: "questionmark.circle")
            }
        }
        .sheet(isPresented: $isShowingContext) {
            NavigationStack {
                ScrollView {
                    switch message.name {
                    case Tool.searchWeb.function.name:
                        VStack {
                            Text(message.content ?? "None")
                                .textSelection(.enabled)
                                .padding()
                        }
                    case Tool.generateWebBrowse.function.name:
                        VStack {
                            Markdown(message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                                .markdownTheme(.mate)
                                .markdownCodeSyntaxHighlighter(.splash(theme: .sunset(withFont: .init(size: monospaceFontSize))))
                                .textSelection(.enabled)
                                .padding()
                        }
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
    
    #if os(macOS)
    var monospaceFontSize: CGFloat = 11
    #else
    var monospaceFontSize: CGFloat = 12
    #endif
}

struct MessageToolContent: View {
    @Environment(Store.self) var store
    
    let message: Message
    let symbol: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: symbol)
                Text(message.metadata.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            if store.preferences.debug, let content = message.content {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 2)
    }
}

struct MessageToolSourceList: View {
    @Environment(\.openURL) var openURL
    
    let message: Message
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top) {
                ForEach(prepareSources(message.content)) { source in
                    if let url = URL(string: source.url) {
                        Button(action: { openURL(url) }) {
                            MessageToolSource(source: source)
                        }.buttonStyle(.plain)
                    } else {
                        MessageToolSource(source: source)
                    }
                }
            }
        }
        .scrollClipDisabled()
        .padding(.leading, -12)
        .padding(.bottom, 8)
    }
    
    private func prepareSources(_ content: String?) -> [Tool.GenerateWebBrowse.Source] {
        guard let data = content?.data(using: .utf8) else { return [] }
        let sources = try? JSONDecoder().decode([Tool.GenerateWebBrowse.Source].self, from: data)
        return sources ?? []
    }
}

struct MessageToolSource: View {
    let source: Tool.GenerateWebBrowse.Source
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(source.title ?? "Missing title")
                .lineLimit(1)
                .font(.footnote.weight(.semibold))
            Text(URL(string: source.url)?.host() ?? source.url)
                .lineLimit(1)
                .font(.footnote)
            Text(source.summary ?? "Missing summary.")
                .lineLimit(4)
                .font(.footnote)
        }
        .frame(width: 200)
        .padding(12)
        .background(.primary.opacity(0.05))
        .foregroundStyle(.secondary)
        .clipShape(.rect(cornerRadius: 10))
    }
}
