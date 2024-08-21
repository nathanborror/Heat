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
        PreferencesStore.shared.preferences.preferredChatServiceID != nil
    }
    
    private init() {}
    
    // MARK: - Getters
    
    public func get(tools names: Set<String>) -> Set<Tool> {
        let tools = Toolbox.allCases
            .filter { names.contains($0.tool.function.name) }
            .map { $0.tool }
        return Set(tools)
    }
    
    // MARK: - Persistence
    
    static private var preferencesJSON = "preferences.json"
    
    public func restoreAll() async throws {
//        do {
//            let preferences: Preferences? = try await persistence.load(object: Self.preferencesJSON)
//            
//            await MainActor.run {
//                self.preferences = preferences ?? self.preferences
//            }
//            logger.info("Persistence: all data restored")
//        } catch {
//            logger.warning("Persistence: all data failed to restore")
//            try resetAll()
//        }
    }
    
    public func saveAll() async throws {
//        try await persistence.save(filename: Self.preferencesJSON, object: preferences)
//        logger.info("Persistence: all data saved")
    }
    
    public func deleteAll() throws {
//        try persistence.deleteAll()
//        try resetAll()
//        logger.info("Persistence: all data deleted")
    }
    
    public func resetAll() throws {
//        preferences = .init()
//        logger.info("Persistence: all data reset")
    }
}
