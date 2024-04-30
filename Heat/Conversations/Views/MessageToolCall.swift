import SwiftUI
import GenKit
import HeatKit

struct MessageToolCall: View {
    let message: Message
    
    var body: some View {
        if let toolCalls = message.toolCalls {
            ForEach(toolCalls, id: \.id) { toolCall in
                VStack(alignment: .leading, spacing: 0) {
                    if let tool = AgentTools(name: toolCall.function.name) {
                        switch tool {
                        case .generateImages:
                            MessageToolCallContent(label: "Generating images...", symbol: "circle")
                        case .generateMemory:
                            MessageToolCallContent(label: "Remembering...", symbol: "circle")
                        case .searchFiles:
                            MessageToolCallContent(label: "Searching files...", symbol: "circle")
                        case .searchCalendar:
                            MessageToolCallContent(label: "Searching calendar...", symbol: "circle")
                        case .searchWeb:
                            MessageToolCallContent(label: "Searching the web...", symbol: "circle")
                        case .browseWeb:
                            MessageToolCallContent(label: "Browsing the web...", symbol: "circle")
                        }
                    } else {
                        Text("Missing tool calls.")
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
