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
import HeatKit

@MainActor @Observable
final class AppState {
    static let shared = AppState()

    // Providers oversee a specific top-level kind of data and provide methods
    // for mutating and storing the data they're responsible for.

    let agentsProvider: AgentsProvider
    let conversationsProvider: ConversationsProvider
    let messagesProvider: MessagesProvider
    let preferencesProvider: PreferencesProvider

    // Shortcuts

    var debug: Bool { preferencesProvider.preferences.debug }
    var textRendering: Preferences.TextRendering { preferencesProvider.preferences.textRendering }

    private let storage = UserDefaults.standard

    private init() {
        self.agentsProvider = .shared
        self.conversationsProvider = .shared
        self.messagesProvider = .shared
        self.preferencesProvider = .shared
    }

    func reset() async throws {
        try await agentsProvider.reset()
        try await conversationsProvider.reset()
        try await messagesProvider.reset()
        try await preferencesProvider.reset()

        try await preferencesProvider.initializeServices()
    }
}
