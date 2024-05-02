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
            if let name = message.name, let tool = AgentTools(name: name) {
                switch tool {
                case .generateImages:
                    MessageToolContent(message: message, symbol: "checkmark.circle")
                    MessageImagesComponent(attachments: message.attachments)
                case .generateMemory, .searchFiles, .searchCalendar, .searchWeb, .browseWeb:
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

struct MessageImagesComponent: View {
    let attachments: [Message.Attachment]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(attachments.indices, id: \.self) { index in
                    if case .asset(let asset) = attachments[index] {
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
