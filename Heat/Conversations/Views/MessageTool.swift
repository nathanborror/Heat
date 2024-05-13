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
            if let name = message.name, let tool = Toolbox(name: name) {
                switch tool {
                case .generateImages:
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                    MessageToolAttachments(message: message)
                case .searchWeb:
                    MessageToolWebSearch(message: message)
                case .generateMemory, .searchFiles, .searchCalendar, .browseWeb, .generateSuggestions, .generateTitle:
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                }
            } else {
                MessageToolContent(message: message, symbol: "circle.badge.questionmark")
            }
        }
        .sheet(isPresented: $isShowingContext) {
            NavigationStack {
                ScrollView {
                    switch message.name {
                    case Toolbox.searchWeb.name:
                        VStack {
                            Text(message.content ?? "None")
                                .textSelection(.enabled)
                                .padding()
                        }
                    case Toolbox.browseWeb.name:
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
    
    var message: Message
    var symbol: String = "checkmark.circle"
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: symbol)
                Text(message.metadata.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
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

struct MessageToolAttachments: View {
    let message: Message
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(message.attachments.indices, id: \.self) { index in
                    if case .asset(let asset) = message.attachments[index] {
                        PictureView(asset: asset)
                            .frame(width: 200, height: 200)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                }
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

struct MessageToolWebSearch: View {
    let message: Message
    var response: WebSearchTool.Response? = nil
    
    init(message: Message) {
        self.message = message
        guard let content = message.content, let data = content.data(using: .utf8) else { return }
        self.response = try? JSONDecoder().decode(WebSearchTool.Response.self, from: data)
    }
    
    var body: some View {
        if let response {
            switch response.kind {
            case .website, .news:
                MessageToolContent(message: message)
            case .image:
                MessageToolContent(message: message)
                MessageToolWebSearchImages(images: response.results)
            }
        }
    }
}

struct MessageToolWebSearchImages: View {
    let images: [WebSearchResult]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(images.indices, id: \.self) { index in
                    Button(action: {}) {
                        AsyncImage(url: images[index].image) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.primary
                        }
                        .frame(width: 200, height: 200)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .padding(.vertical, 8)
        .padding(.leading, -12)
    }
}
