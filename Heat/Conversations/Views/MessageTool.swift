import SwiftUI
import GenKit
import HeatKit
import MarkdownUI
import Splash

struct MessageTool: View {
    @Environment(\.openURL) var openURL
    
    let message: Message
    
    @State private var isShowingContext = false
    
    var body: some View {
        VStack(alignment: .leading) {
            switch message.name {
            case Tool.generateWebSearch.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(message: message, symbol: "macwindow")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.generateWebBrowse.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(message: message, symbol: "macwindow.and.cursorarrow")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
                
                ScrollView(.horizontal) {
                    HStack(alignment: .top) {
                        ForEach(handleWebPageSummaries(message.content)) { article in
                            if let url = URL(string: article.url) {
                                Button(action: { openURL(url) }) {
                                    VStack(alignment: .leading) {
                                        Text(URL(string: article.url)?.host() ?? article.url)
                                            .lineLimit(1)
                                            .font(.footnote.weight(.semibold))
                                        Text(article.summary)
                                            .lineLimit(4)
                                            .font(.footnote)
                                    }
                                    .frame(width: 200)
                                    .padding(12)
                                    .background(.primary.opacity(0.05))
                                    .foregroundStyle(.secondary)
                                    .clipShape(.rect(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            } else {
                                VStack(alignment: .leading) {
                                    Text(URL(string: article.url)?.host() ?? article.url)
                                        .lineLimit(1)
                                        .font(.footnote.weight(.semibold))
                                    Text(article.summary)
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
                    }
                }
                .scrollClipDisabled()
                .padding(.leading, -12)
                .padding(.bottom, 8)
            case Tool.generateImages.function.name:
                MessageToolContent(message: message, symbol: "photo")
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
            default:
                EmptyView()
            }
        }
        .sheet(isPresented: $isShowingContext) {
            NavigationStack {
                ScrollView {
                    switch message.name {
                    case Tool.generateWebSearch.function.name:
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
    
    private func handleWebPageSummaries(_ content: String?) -> [Article] {
        guard let data = content?.data(using: .utf8) else { return [] }
        var articles: [Article] = []
        do {
            articles = try JSONDecoder().decode([Article].self, from: data)
        } catch {
            print(error)
        }
        return articles
    }
    
    struct Article: Codable, Identifiable {
        var id: String { return url }
        var url: String = ""
        var summary: String = ""
    }
    
    #if os(macOS)
    var monospaceFontSize: CGFloat = 11
    #else
    var monospaceFontSize: CGFloat = 12
    #endif
}

struct MessageToolContent: View {
    let message: Message
    let symbol: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: symbol)
            Text(message.metadata["label"] ?? "Unknown")
            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }
}
