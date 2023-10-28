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
            NavigationStack {
                ChatView(chatID: nil)
            }
            .onAppear {
                handleRestore()
            }
            .onChange(of: scenePhase) { _, _ in
                handlePhaseChange()
            }
        }
        .environment(store)
    }
    
    func handleRestore() {
        Task {
            do {
                try await store.restore()
                try await store.loadModels()
            } catch {
                logger.error("Persistence Restore: \(error, privacy: .public)")
            }
        }
    }
    
    func handleSave() async {
        do { try await store.saveAll() }
        catch { logger.error("Persistence Save: \(error, privacy: .public)") }
    }
    
    func handlePhaseChange() {
        guard scenePhase == .background else { return }
        Task { await handleSave() }
    }
}
