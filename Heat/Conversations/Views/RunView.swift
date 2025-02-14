import SwiftUI
import GenKit
import HeatKit

struct RunView: View {
    let run: Run

    @State private var showAllMessages = false

    init(_ run: Run) {
        self.run = run
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if run.messages.count > 1 {
                Button {
                    showAllMessages.toggle()
                } label: {
                    Text("Show All Messages")
                }
            }

            ForEach(run.messages) { message in
                if showAllMessages {
                    MessageView(message)
                } else {
                    if message.shouldShowInRun {
                        MessageView(message)
                    }
                }
            }
        }
    }
}
