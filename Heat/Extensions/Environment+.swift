import SwiftUI

private struct DebugKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct MarkdownKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    
    var debug: Bool {
        get { self[DebugKey.self] }
        set { self[DebugKey.self] = newValue }
    }
    
    var useMarkdown: Bool {
        get { self[MarkdownKey.self] }
        set { self[MarkdownKey.self] = newValue }
    }
}
