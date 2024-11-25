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
                    MessageAttachments(message.attachments)
                        #if os(macOS)
                        .frame(width: 300, height: 300)
                        .scaleEffect(1.05)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        }
                        #endif
                case .searchWeb:
                    MessageToolContent("Search results", message.content, lineLimit: lineLimit)
                case .browseWeb:
                    MessageToolContent("Read webpage", message.content, lineLimit: lineLimit)
                case .generateMemory:
                    MessageToolContent("Remembering", message.content, lineLimit: lineLimit)
                case .searchCalendar:
                    MessageToolContent("Calendar search results", message.content, lineLimit: lineLimit)
                case .generateTitle, .generateSuggestions:
                    MessageToolContent(message.metadata.label, nil)
                }
            } else {
                MessageToolContent(message.metadata.label, nil)
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
                            RenderText(message.content)
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

struct MessageToolContent: View {
    let title: String?
    let content: String?
    let lineLimit: Int

    init(_ title: String?, _ content: String?, lineLimit: Int = 3) {
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
                Text(content)
                    .lineLimit(lineLimit)
                    .font(.system(size: textFontSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .background(.black)
    }
}
