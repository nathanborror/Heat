import SwiftUI
import GenKit
import HeatKit

struct MessageToolCall: View {
    let message: Message
    
    var body: some View {
        if let toolCalls = message.toolCalls {
            ForEach(toolCalls, id: \.id) { toolCall in
                VStack(alignment: .leading, spacing: 0) {
                    if let tool = Toolbox(name: toolCall.function.name) {
                        switch tool {
                        case .generateImages:
                            content("Generating images...")
                        case .generateMemory:
                            content("Remembering...")
                        case .generateSuggestions:
                            content("Generating suggestions...")
                        case .generateTitle:
                            content("Generating title...")
                        case .searchFiles:
                            content("Searching files...")
                        case .searchCalendar:
                            content("Searching calendar...")
                        case .searchWeb:
                            content("Searching the web...")
                        case .browseWeb:
                            content("Browsing the web...")
                        }
                    } else {
                        Text("Missing tool calls.")
                    }
                    Text(toolCall.function.arguments)
                        .font(.footnote)
                        .foregroundStyle(.secondary.opacity(0.5))
                        .padding(.bottom, 4)
                }
                #if os(macOS)
                .padding(.leading, 24)
                #endif
            }
        } else {
            Text("Missing tool calls.")
        }
    }
    
    func content(_ label: String) -> MessageToolCallContent {
        .init(label: label)
    }
}

struct MessageToolCallContent: View {
    var label: String
    var symbol: String = "circle"
    
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
