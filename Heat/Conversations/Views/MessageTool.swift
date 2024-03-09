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
            case Tool.generateWebSearch.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(content: "Searching", symbol: "magnifyingglass")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.generateWebBrowse.function.name:
                Button(action: { isShowingContext = true }) {
                    MessageToolContent(content: "Browsing", symbol: "macwindow")
                }
                .buttonStyle(.plain)
                .tint(.secondary)
            case Tool.generateImages.function.name:
                MessageToolContent(content: "Generating Images", symbol: "photo")
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
    
    #if os(macOS)
    var monospaceFontSize: CGFloat = 11
    #else
    var monospaceFontSize: CGFloat = 12
    #endif
}

struct MessageToolContent: View {
    let content: String
    let symbol: String
    
    var body: some View {
        HStack {
            Image(systemName: symbol)
            Text(content)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }
}

#Preview {
    ScrollView {
        VStack {
            
            // Browser example
            MessageTool(
                message: .init(
                    role: .tool,
                    name: Tool.generateWebBrowse.function.name
                )
            )
            .padding()
        }
    }
    .background(.background)
    .frame(width: 400, height: 700)
}
