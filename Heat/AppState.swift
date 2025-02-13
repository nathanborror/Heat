/*
 ___   ___   ______   ________   _________
/__/\ /__/\ /_____/\ /_______/\ /________/\
\::\ \\  \ \\::::_\/_\::: _  \ \\__.::.__\/
 \::\/_\ .\ \\:\/___/\\::(_)  \ \  \::\ \
  \:: ___::\ \\::___\/_\:: __  \ \  \::\ \
   \: \ \\::\ \\:\____/\\:.\ \  \ \  \::\ \
    \__\/ \::\/ \_____\/ \__\/\__\/   \__\/
 */

import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "AppState", category: "App")

@MainActor @Observable
final class AppState {

    static let release = AppState()
    static let development = AppState()

    enum Error: Swift.Error, CustomStringConvertible {
        case restorationError(String)
        case serviceError(String)

        public var description: String {
            switch self {
            case .restorationError(let detail):
                "Restoration error: \(detail)"
            case .serviceError(let detail):
                "Service error: \(detail)"
            }
        }
    }

    // Providers oversee a specific top-level kind of data and provide methods
    // for mutating and storing the data they're responsible for.

    let agentsProvider: AgentsProvider
    let conversationsProvider: ConversationsProvider
    let messagesProvider: MessagesProvider
    let memoryProvider: MemoryProvider
    let preferencesProvider: PreferencesProvider

    // Shortcuts

    var debug: Bool { preferencesProvider.preferences.debug }
    var textRendering: Preferences.TextRendering { preferencesProvider.preferences.textRendering }

    private let storage = UserDefaults.standard

    enum Kind {
        case preview
        case development
        case release
    }

    private init(kind: Kind = .development) {
        self.agentsProvider = .shared
        self.conversationsProvider = .shared
        self.messagesProvider = .shared
        self.memoryProvider = .shared
        self.preferencesProvider = .shared
    }

    func reset() async throws {
        do {
            try await agentsProvider.reset()
            try await conversationsProvider.reset()
            try await messagesProvider.reset()
            try await memoryProvider.reset()
            try await preferencesProvider.reset()
        } catch {
            throw Error.restorationError("\(error)")
        }
        do {
            try await preferencesProvider.initializeServices()
        } catch {
            throw Error.serviceError("\(error)")
        }
    }
}

