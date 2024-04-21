import SwiftUI
import GenKit
import HeatKit

struct MessageToolCall: View {
    let message: Message
    
    var body: some View {
        if let toolCalls = message.toolCalls {
            ForEach(toolCalls, id: \.id) { toolCall in
                VStack(alignment: .leading, spacing: 0) {
                    switch toolCall.function.name {
                    case Tool.generateWebSearch.function.name:
                        MessageToolCallContent(label: "Searching the web...", symbol: "circle")
                    case Tool.generateWebBrowse.function.name:
                        MessageToolCallContent(label: "Browsing the web...", symbol: "circle")
                    case Tool.generateImages.function.name:
                        MessageToolCallContent(label: "Generating images...", symbol: "circle")
                    case Tool.generateMemory.function.name:
                        MessageToolCallContent(label: "Remembering...", symbol: "circle")
                    default:
                        MessageToolCallContent(label: "\(toolCall.function.name)...", symbol: "questionmark.circle")
                    }
                    Text(toolCall.function.arguments)
                        .font(.footnote)
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(.bottom, 4)
                }
            }
        } else {
            Text("Missing tool calls.")
        }
    }
}

struct MessageToolCallContent: View {
    let label: String
    let symbol: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: symbol)
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.vertical, 2)
    }
}
