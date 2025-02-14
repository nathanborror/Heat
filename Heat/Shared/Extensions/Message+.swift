import SwiftUI
import GenKit
import HeatKit

extension Message {

    var shouldShowInRun: Bool {

        // Only show some tool responses
        if role == .tool, let name = name, let toolName = Toolbox(name: name) {
            switch toolName {
            case .generateImages:
                return true
            case .generateMemory:
                return true
            case .generateSuggestions:
                return true
            case .generateTitle:
                return true
            case .searchCalendar:
                return false
            case .searchWeb:
                return false
            case .browseWeb:
                return false
            }
        }

        if role == .assistant, let toolCalls = toolCalls {
            for toolCall in toolCalls {
                switch Toolbox(name: toolCall.function.name) {
                case .generateMemory:
                    return true
                case .generateImages:
                    return true
                default:
                    return false
                }
            }
        }

        // When in doubt, show message
        return true
    }
}

