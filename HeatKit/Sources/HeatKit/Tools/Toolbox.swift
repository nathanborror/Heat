import Foundation
import SharedKit
import GenKit

public enum Toolbox: CaseIterable, Sendable {
    case generateImages
    case searchCalendar
    case searchWeb
    case browseWeb
    
    // Because the name is influential in the prompting it may change so this is
    // a good place to put legacy names so they return the correct tool.
    public init?(name: String?) {
        switch name {
        case ImageGeneratorTool.function.name:
            self = .generateImages
        case CalendarSearchTool.function.name:
            self = .searchCalendar
        case WebSearchTool.function.name:
            self = .searchWeb
        case WebBrowseTool.function.name:
            self = .browseWeb
        default:
            return nil
        }
    }
    
    public var tool: Tool {
        switch self {
        case .generateImages:
            Tool(function: ImageGeneratorTool.function)
        case .searchCalendar:
            Tool(function: CalendarSearchTool.function)
        case .searchWeb:
            Tool(function: WebSearchTool.function)
        case .browseWeb:
            Tool(function: WebBrowseTool.function)
        }
    }
    
    public var name: String {
        tool.function?.name ?? ""
    }
    
    public static func get(names: Set<String>) -> [Tool] {
        return Toolbox.allCases
            .filter { names.contains($0.tool.function?.name ?? "") }
            .map { $0.tool }
    }
}

public enum ToolboxError: Error {
    case failedDecoding
}
