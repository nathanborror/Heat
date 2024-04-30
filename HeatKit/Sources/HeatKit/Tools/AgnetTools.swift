import Foundation
import GenKit

public enum AgentTools: CaseIterable {
    case generateImages
    case generateMemory
    case searchFiles
    case searchCalendar
    case searchWeb
    case browseWeb
    
    // Because the name is influential in the prompting it may change so this is
    // a good place to put legacy names so they return the correct tool.
    public init?(name: String) {
        switch name {
        case Tool.generateImages.function.name:
            self = .generateImages
        case Tool.generateMemory.function.name:
            self = .generateMemory
        case Tool.searchFiles.function.name:
            self = .searchFiles
        case Tool.searchCalendar.function.name:
            self = .searchCalendar
        case Tool.searchWeb.function.name:
            self = .searchWeb
        case Tool.generateWebBrowse.function.name:
            self = .browseWeb
        default:
            return nil
        }
    }
    
    public var tool: Tool {
        switch self {
        case .generateImages:
            return Tool.generateImages
        case .generateMemory:
            return Tool.generateMemory
        case .searchFiles:
            return Tool.searchFiles
        case .searchCalendar:
            return Tool.searchCalendar
        case .searchWeb:
            return Tool.searchWeb
        case .browseWeb:
            return Tool.generateWebBrowse
        }
    }
}
