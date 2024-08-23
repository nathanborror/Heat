import Foundation
import SwiftUI

@MainActor
class HapticManager {
    static var shared = HapticManager()
    
    enum FeedbackStyle {
        case heavy, light, medium, rigid, soft
    }
    
    func tap(style: FeedbackStyle) {
        #if !os(macOS)
        switch style {
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        #endif
    }
}
