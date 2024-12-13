import SwiftUI
import GenKit
import HeatKit

struct MessageTool: View {
    let message: Message
    let lineLimit: Int

    @State private var isShowingContext = false

    init(_ message: Message, lineLimit: Int = 3) {
        self.message = message
        self.lineLimit = lineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let name = message.name, let tool = Toolbox(name: name) {
                switch tool {
                case .generateImages:
                    MessageToolContent("Generate Images", message.content, lineLimit: lineLimit)
                case .searchWeb:
                    MessageToolContent("Search results", message.content, lineLimit: lineLimit)
                case .browseWeb:
                    MessageToolContent("Read webpage", message.content, lineLimit: lineLimit)
                case .generateMemory:
                    MessageToolContent("Remembering", message.content, lineLimit: lineLimit)
                case .searchCalendar:
                    MessageToolContent("Calendar search results", message.content, lineLimit: lineLimit)
                case .generateTitle, .generateSuggestions:
                    MessageToolContent(message.metadata?.label, nil)
                }
            } else {
                MessageToolContent(message.metadata?.label, nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isShowingContext) {
            NavigationStack {
                ScrollView {
                    switch message.name {
                    case Toolbox.searchWeb.name:
                        VStack {
                            if let content = message.content {
                                ForEach(content.indices, id: \.self) { index in
                                    switch content[index] {
                                    case .text(let text):
                                        Text(text)
                                            .textSelection(.enabled)
                                            .padding()
                                    default:
                                        Text("Unhandled content type")
                                    }
                                }
                            }
                        }
                    case Toolbox.browseWeb.name:
                        VStack {
                            if let content = message.content {
                                ForEach(content.indices, id: \.self) { index in
                                    switch content[index] {
                                    case .text(let text):
                                        RenderText(text)
                                            .textSelection(.enabled)
                                            .padding()
                                    default:
                                        Text("Unhandled content type")
                                    }
                                }
                            }

                        }
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct MessageToolContent: View {
    let title: String?
    let content: [Message.Content]?
    let lineLimit: Int

    init(_ title: String?, _ content: [Message.Content]?, lineLimit: Int = 3) {
        self.title = title
        self.content = content
        self.lineLimit = lineLimit
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title {
                Text(title)
                    .font(.system(size: textFontSize, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let content {
                ForEach(content.indices, id: \.self) { index in
                    switch content[index] {
                    case .text(let text):
                        Text(text)
                            .lineLimit(lineLimit)
                            .font(.system(size: textFontSize))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    default:
                        Text("Unhandled content type")
                    }
                }
            }
        }
    }

    #if os(macOS)
    let textFontSize: CGFloat = 12
    #else
    let textFontSize: CGFloat = 14
    #endif
}

struct MessageToolWebSearch: View {
    let message: Message
    var response: WebSearchTool.Response? = nil

    init(message: Message) {
        self.message = message
        guard case .text(let text) = message.content?.first else { return }
        guard let data = text.data(using: .utf8) else { return }
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
                    if let url = images[index].image {
                        PictureView(url: url)
                            .aspectRatio(1.0, contentMode: .fit)    // Forces a square aspect ratio.
                            .containerRelativeFrame([.horizontal])  // Makes the frame width fill the scroll view.
                            .clipped()
                            .onTapGesture {
                                openURL(images[index].url)
                            }
                    }
                }
                Spacer()
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .background(.black)
    }
}
