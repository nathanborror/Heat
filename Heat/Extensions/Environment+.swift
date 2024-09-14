import SwiftUI
import HeatKit

private struct DebugKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct TextRenderingKey: EnvironmentKey {
    static let defaultValue: Preferences.TextRendering = .markdown
}

extension EnvironmentValues {
    
    var debug: Bool {
        get { self[DebugKey.self] }
        set { self[DebugKey.self] = newValue }
    }
    
    var textRendering: Preferences.TextRendering {
        get { self[TextRenderingKey.self] }
        set { self[TextRenderingKey.self] = newValue }
    }
}
