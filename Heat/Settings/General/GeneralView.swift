import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct GeneralView: View {
    @Environment(AppState.self) var state

    var body: some View {
        #if os(macOS)
        GeneralForm()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading)
            .layoutPriority(1)
        #else
        NavigationStack {
            GeneralForm()
                .navigationTitle("General")
                .navigationBarTitleDisplayMode(.inline)
        }
        #endif
    }
}
