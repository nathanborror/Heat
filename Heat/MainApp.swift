import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var store = Store.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await handleRestore() }
                .onChange(of: scenePhase) { _, newValue in
                    switch newValue {
                    case .inactive:
                        Task { await handleSave() }
                    default: break
                    }
                }
        }
        .environment(store)
    }
    
    func handleRestore() async {
        do { try await store.restore() }
        catch { logger.error("Persistence Restore: \(error, privacy: .public)") }
    }
    
    func handleSave() async {
        do { try await store.saveAll() }
        catch { logger.error("Persistence Save: \(error, privacy: .public)") }
    }
}
