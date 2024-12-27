import SwiftUI
import GenKit
import HeatKit

struct RunView: View {
    @Environment(\.colorScheme) var colorScheme

    let run: Run

    init(_ run: Run) {
        self.run = run
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(run.messages) { message in
                MessageView(message)
            }
        }
    }
}
