import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var store = Store.shared
    @State private var router = Router.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await handleRestore()
                }
                .sheet(item: $router.presenting) { destination in
                    NavigationStack(path: $router.path) {
                        Group {
                            switch destination {
                            case .chat:
                                EmptyView()
                            case .agentForm:
                                AgentForm()
                            case .agentList:
                                AgentListView()
                            case .preferences:
                                SettingsView()
                            }
                        }
                        .navigationDestination(for: Router.Destination.self) { destination in
                            switch destination {
                            case .agentForm:
                                AgentForm()
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .environment(store)
                    .environment(router)
                    .frame(idealWidth: 400, idealHeight: 500)
                }
                .onChange(of: scenePhase) { _, newValue in
                    switch newValue {
                    case .inactive:
                        Task { await handleSave() }
                    default: break
                    }
                }
        }
        .environment(store)
        .environment(router)
    }
    
    func handleRestore() async {
        do {
            try await store.restore()
            try await store.models()
        } catch {
            logger.error("Persistence Restore: \(error, privacy: .public)")
        }
    }
    
    func handleSave() async {
        do { try await store.saveAll() }
        catch { logger.error("Persistence Save: \(error, privacy: .public)") }
    }
}
