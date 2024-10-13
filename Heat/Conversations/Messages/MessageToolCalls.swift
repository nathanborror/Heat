import SwiftUI
import GenKit
import HeatKit

struct MessageToolCalls: View {
    let toolCalls: [ToolCall]
    
    init(_ toolCalls: [ToolCall]?) {
        self.toolCalls = toolCalls ?? []
    }
    
    var body: some View {
        if !toolCalls.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(toolCalls, id: \.id) { toolCall in
                    if let tool = Toolbox(name: toolCall.function.name) {
                        switch tool {
                        case .generateImages:
                            MessageToolCallContent("Generating images...")
                        case .generateMemory:
                            MessageToolCallContent("Remembering...")
                        case .generateSuggestions:
                            MessageToolCallContent("Generating suggestions...")
                        case .generateTitle:
                            MessageToolCallContent("Generating title...")
                        case .searchCalendar:
                            MessageToolCallContent("Searching calendar...")
                        case .searchWeb:
                            MessageToolCallContent("Searching the web...")
                        case .browseWeb:
                            MessageToolCallContent("Browsing the web...")
                        }
                    } else {
                        Text("Missing tool calls.")
                    }
                    MessageToolCallArguments(toolCall.function)
                }
            }
        }
    }
}

struct MessageToolCallContent: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: textFontSize, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    #if os(macOS)
    let textFontSize: CGFloat = 14
    #else
    let textFontSize: CGFloat = 16
    #endif
}

struct MessageToolCallArguments: View {
    let function: ToolCall.FunctionCall
    
    init(_ function: ToolCall.FunctionCall) {
        self.function = function
    }
    
    var body: some View {
        Text(subtext)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .lineLimit(4)
    }
    
    var subtext: String {
        switch function.name {
        case Toolbox.searchWeb.name:
            let args = try? WebSearchTool.Arguments(function.arguments)
            return "\"\(args?.query ?? "")\""
        case Toolbox.browseWeb.name:
            let args = try? WebBrowseTool.Arguments(function.arguments)
            return args?.url ?? ""
        case Toolbox.generateImages.name:
            let args = try? ImageGeneratorTool.Arguments(function.arguments)
            return args?.prompts.joined(separator: ", ") ?? ""
        default:
            return function.arguments
        }
    }
}
