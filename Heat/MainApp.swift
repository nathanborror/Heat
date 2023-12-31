import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var store = Store.shared
    @State private var conversationViewModel = ConversationViewModel(store: Store.shared)
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConversationView()
            }
            .onChange(of: scenePhase) { _, _ in
                handlePhaseChange()
            }
            .onAppear {
                handleRestore()
            }
        }
        .environment(store)
        .environment(conversationViewModel)
    }
    
    func handleRestore() {
        Task {
            do {
                try await store.restore()
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

enum AppError: LocalizedError {
    case missingToken
    case missingHost
    case missingModel
    
    public var errorDescription: String? {
        switch self {
        case .missingToken:
            "Missing auth token"
        case .missingHost:
            "Missing host URL"
        case .missingModel:
            "Missing model"
        }
    }
    
    var explanation: String {
        switch self {
        case .missingToken:
            "Check that your OpenAI token has been added to Preferences."
        case .missingHost:
            "Check that your Ollama host URL has been added to Preferences."
        case .missingModel:
            "Check that you've selected a model in Preferences."
        }
    }
}
