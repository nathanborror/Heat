import SwiftUI
import GenKit
import HeatKit

struct MessageTool: View {
    let message: Message
    let lineLimit: Int
    
    @State private var isShowingContext = false
    
    init(_ message: Message, lineLimit: Int = 4) {
        self.message = message
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                    MessageToolTitle("Search results")
                    MessageToolContent(message.content, lineLimit: lineLimit)
                case .browseWeb:
                    MessageToolTitle("Read webpage")
                    MessageToolContent(message.content, lineLimit: lineLimit)
                case .generateMemory:
                    MessageToolTitle("Remembering")
                    MessageToolContent(message.content, lineLimit: lineLimit)
                case .searchCalendar:
                    MessageToolTitle("Calendar search results")
                    MessageToolContent(message.content, lineLimit: lineLimit)
                case .generateTitle, .generateSuggestions:
                    MessageToolTitle(message.metadata.label)
                }
            } else {
                MessageToolTitle(message.metadata.label)
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

struct MessageToolTitle: View {
    @Environment(\.debug) private var debug
    
    let content: String?
    
    init(_ content: String?) {
        self.content = content
    }
    
    var body: some View {
        if let content {
            Text(content)
                .font(.system(size: textFontSize, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    #if os(macOS)
    let textFontSize: CGFloat = 14
    #else
    let textFontSize: CGFloat = 16
    #endif
}

struct MessageToolContent: View {
    @Environment(\.debug) private var debug
    
    let content: String?
    let lineLimit: Int
    
    init(_ content: String?, lineLimit: Int = 4) {
        self.content = content
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        if let content {
            Text(content)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(lineLimit)
        }
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
        .background(.black)
    }
}
