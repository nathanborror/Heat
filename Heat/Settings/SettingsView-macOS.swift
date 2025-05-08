import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PreferencesView: View {
    @Environment(AppState.self) var state

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                Tab("General", systemImage: "person.text.rectangle", value: 0) {
                    GeneralView()
                        .frame(maxWidth: 600, alignment: .center)
                }

                Tab("Permissions", systemImage: "key.2.on.ring", value: 1) {
                    PermissionsView()
                }

                Tab("Services", systemImage: "hand.palm.facing", value: 2) {
                    ServicesView()
                }

                Tab("Instructions", systemImage: "helm", value: 3) {
                    InstructionsView()
                }

                Tab("Tools", systemImage: "ellipsis.curlybraces", value: 4) {
                    ContentUnavailableView("Not Implemented", systemImage: "ellipsis.curlybraces")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(minHeight: 400)
        .navigationTitle("Settings")
        .scenePadding()
    }
}
