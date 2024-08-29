import SwiftUI
import GenKit
import HeatKit
import MarkdownUI

struct MessageTool: View {
    let message: Message
    
    @State private var isShowingContext = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if let name = message.name, let tool = Toolbox(name: name) {
                switch tool {
                case .generateImages:
                    VStack(alignment: .leading) {
                        MessageAttachments(message: message)
                            #if os(macOS)
                            .frame(width: 300, height: 300)
                            .scaleEffect(1.05)
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            }
                            #endif
                            .padding(.bottom, 12)
                    }
                    #if os(macOS)
                    .padding(.leading, 12)
                    #endif
                case .searchWeb:
                    VStack(alignment: .leading) {
                        MessageToolContent(message: message)
                            .padding(.top, 8)
                        MessageToolWebSearch(message: message)
                            #if os(macOS)
                            .frame(width: 200, height: 200)
                            .scaleEffect(1.05)
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            }
                            #endif
                            .padding(.bottom, 12)
                    }
                    #if os(macOS)
                    .padding(.leading, 12)
                    #endif
                default:
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                        .padding(.horizontal, 12)
                }
            } else {
                MessageToolContent(message: message, symbol: "circle.badge.questionmark")
                    .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                                .markdownTheme(.app)
                                .markdownCodeSyntaxHighlighter(.app)
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
}

struct MessageToolBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.black)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 5))
            .padding(.horizontal, 12)
    }
}

struct MessageToolContent: View {
    @Environment(\.debug) private var debug
    
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
            
            if debug, let content = message.content {
                Text(content)
                    .font(.footnote)
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 2)
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
        if let response, case .image = response.kind {
            MessageToolWebSearchImages(images: response.results)
        }
    }
}

struct MessageToolWebSearchImages: View {
    @Environment(\.openURL) var openURL
    
    let images: [WebSearchResult]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(images.indices, id: \.self) { index in
                    PictureView(asset: .init(name: images[index].image?.absoluteString ?? "", kind: .image, location: .url))
                        .aspectRatio(1.0, contentMode: .fit)    // Forces a square aspect ratio.
                        .containerRelativeFrame([.horizontal])  // Makes the frame width fill the scroll view.
                        .clipped()
                        .onTapGesture {
                            openURL(images[index].url)
                        }
                }
                Spacer()
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}
