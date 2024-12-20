import SwiftUI
import GenKit
import HeatKit

struct RunView: View {
    @Environment(\.colorScheme) var colorScheme

    let run: Run

    @State private var isInspecting = false

    init(_ run: Run) {
        self.run = run
    }

    /// The final response given for the run of work.
    var response: Message? {
        run.messages.last
    }

    var body: some View {
        if run.messages.count == 1 {
            MessageView(run.messages[0])
        } else {
            VStack(alignment: .leading, spacing: 12) {

                // Show steps of work toggle
                stepsButton

                // Show the final response
                if let response {
                    MessageView(response)
                }
            }
        }
    }

    var stepsButton: some View {
        Button {
            isInspecting.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                if let pretty = run.elapsedPretty {
                    Text("\(run.steps.count) steps · \(pretty)")
                } else {
                    Text("\(run.steps.count) steps")
                }
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.05), in: .rect(cornerRadius: 10))
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 10)
                        .inset(by: 1)
                        .stroke(.tint.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isInspecting, arrowEdge: .leading) {
            NavigationStack {
                RunStepsView(messages: run.steps)
            }
            #if os(macOS)
            .frame(width: 500, height: 600)
            #endif
        }
    }
}

struct RunStepsView: View {
    let messages: [Message]

    var body: some View {
        List {
            ForEach(messages) { message in
                NavigationLink {
                    RunStepDetail(message)
                } label: {
                    MessageView(message)
                }
                .buttonStyle(.plain)
                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Steps")
        .background(.background)
    }
}

struct RunStepDetail: View {
    let message: Message

    init(_ message: Message) {
        self.message = message
    }

    var body: some View {
        ScrollView {
            MessageView(message, lineLimit: .max)
        }
        .navigationTitle("Details")
        .background(.background)
    }
}
