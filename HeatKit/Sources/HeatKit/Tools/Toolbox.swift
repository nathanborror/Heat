import Foundation
import SharedKit
import GenKit

public enum Toolbox: CaseIterable {
    case generateImages
    case generateMemory
    case generateSuggestions
    case generateTitle
    case searchFiles
    case searchCalendar
    case searchWeb
    case browseWeb
    
    // Because the name is influential in the prompting it may change so this is
    // a good place to put legacy names so they return the correct tool.
    public init?(name: String) {
        switch name {
        case ImageGeneratorTool.function.name:
            self = .generateImages
        case MemoryTool.function.name:
            self = .generateMemory
        case SuggestTool.function.name:
            self = .generateSuggestions
        case TitleTool.function.name:
            self = .generateTitle
        case FileSearchTool.function.name:
            self = .searchFiles
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
        case .generateMemory:
            Tool(function: MemoryTool.function)
        case .generateSuggestions:
            Tool(function: SuggestTool.function)
        case .generateTitle:
            Tool(function: TitleTool.function)
        case .searchFiles:
            Tool(function: FileSearchTool.function)
        case .searchCalendar:
            Tool(function: CalendarSearchTool.function)
        case .searchWeb:
            Tool(function: WebSearchTool.function)
        case .browseWeb:
            Tool(function: WebBrowseTool.function)
        }
    }
    
    public var name: String {
        tool.function.name
    }
    
    public static let ignore: [Toolbox] = [
        .generateSuggestions,
    ]
}
