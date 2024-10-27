import SwiftUI
import SharedKit
import GenKit

extension Asset {

    var backgroundColor: Color? {
        guard let hex = background else { return nil }
        return Color(hex: hex)
    }

    var foregroundColor: Color? {
        guard let hex = foreground else { return nil }
        return Color(hex: hex)
    }
}
