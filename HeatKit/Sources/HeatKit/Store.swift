import Foundation
import Observation
import SharedKit
import GenKit
import OSLog

private let logger = Logger(subsystem: "Store", category: "HeatKit")

@Observable
@MainActor
public final class Store {
    
    public static let shared = Store()
    
    public var isChatAvailable: Bool {
        PreferencesProvider.shared.preferences.preferredChatServiceID != nil
    }
    
    private init() {}
    
    // MARK: - Getters
    
    public func get(tools names: Set<String>) -> Set<Tool> {
        let tools = Toolbox.allCases
            .filter { names.contains($0.tool.function.name) }
            .map { $0.tool }
        return Set(tools)
    }
}
