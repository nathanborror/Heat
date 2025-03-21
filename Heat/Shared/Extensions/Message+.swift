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
