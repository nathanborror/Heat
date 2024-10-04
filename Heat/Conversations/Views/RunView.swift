import SwiftUI
import GenKit
import HeatKit

struct RunView: View {
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
            VStack(alignment: .leading, spacing: 0) {
                
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
                    RunStepDetail(message.content)
                } label: {
                    MessageView(message)
                }
                .buttonStyle(.plain)
                .listRowInsets(.init(top: 12, leading: 4, bottom: 12, trailing: 12))
            }
        }
        .listStyle(.plain)
        .navigationTitle("Steps")
        .background(.background)
    }
}

struct RunStepDetail: View {
    let text: String
    
    init(_ text: String?) {
        self.text = text ?? ""
    }
    
    var body: some View {
        ScrollView {
            Text(text)
                .padding(24)
        }
        .navigationTitle("Details")
    }
}

#Preview("Run") {
    NavigationStack {
        RunView(mock_run)
            .padding(12)
    }
}


#Preview("Run Steps") {
    NavigationStack {
        RunStepsView(messages: mock_run.steps)
    }
}
