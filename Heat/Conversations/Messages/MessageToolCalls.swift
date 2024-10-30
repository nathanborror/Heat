import SwiftUI
import GenKit
import HeatKit

struct MessageToolCalls: View {
    let toolCalls: [ToolCall]
    let lineLimit: Int

    init(_ toolCalls: [ToolCall]?, lineLimit: Int = 3) {
        self.toolCalls = toolCalls ?? []
        self.lineLimit = lineLimit
    }

    var body: some View {
        if !toolCalls.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(toolCalls, id: \.id) { toolCall in
                    VStack(spacing: 0) {
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
                        MessageToolCallArguments(toolCall.function, lineLimit: lineLimit)
                    }
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
    let textFontSize: CGFloat = 12
    #else
    let textFontSize: CGFloat = 14
    #endif
}

struct MessageToolCallArguments: View {
    let function: ToolCall.FunctionCall
    let lineLimit: Int

    init(_ function: ToolCall.FunctionCall, lineLimit: Int = 3) {
        self.function = function
        self.lineLimit = lineLimit
    }

    var body: some View {
        Text(subtext)
            .lineLimit(lineLimit)
            .font(.system(size: textFontSize))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    var subtext: String {
        switch function.name {
        case Toolbox.searchWeb.name:
            let args = try? WebSearchTool.Arguments(function.arguments)
            return "\"\(args?.query ?? "")\""
        case Toolbox.browseWeb.name:
            guard let args = try? WebBrowseTool.Arguments(function.arguments) else {
                return ""
            }
            return """
                Title: \(args.title)
                URL: \(args.url)
                Instructions:
                \(args.instructions)
                """
        case Toolbox.generateImages.name:
            let args = try? ImageGeneratorTool.Arguments(function.arguments)
            return args?.prompts.joined(separator: ", ") ?? ""
        default:
            return function.arguments
        }
    }

    #if os(macOS)
    let textFontSize: CGFloat = 12
    #else
    let textFontSize: CGFloat = 14
    #endif
}
