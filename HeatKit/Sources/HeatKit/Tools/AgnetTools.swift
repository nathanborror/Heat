import Foundation
import GenKit

public enum AgentTools: String, CaseIterable {
    case generateImages
    case generateMemory
    case searchFiles
    case searchCalendar
    case searchWeb
    case browseWeb
    
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
