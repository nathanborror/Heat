import SwiftUI
import GenKit
import HeatKit

struct RunView: View {
    let run: Run
    
    /// The final response given for the run of work.
    var response: Message? {
        guard let last = run.messages.last else { return nil }
        guard last.role == .assistant else { return nil }
        return last
    }
    
    @State private var isInspecting = false
    
    var body: some View {
        if run.messages.count == 1 {
            MessageView(message: run.messages[0])
        } else {
            VStack(alignment: .leading, spacing: 0) {
                
                // Show steps of work toggle
                stepsButton
                    .padding(.horizontal, 12)
                
                // Show the final response
                if let response {
                    MessageView(message: response)
                }
            }
        }
    }
    
    var stepsButton: some View {
        Button {
            isInspecting.toggle()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text("\(run.steps.count) Steps")
                Image(systemName: "info.circle")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.primary.opacity(0.05), in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isInspecting, arrowEdge: .leading) {
            RunStepsView(messages: run.steps)
                .frame(width: 400, height: 400)
        }
    }
}

struct RunStepsView: View {
    let messages: [Message]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(messages) { message in
                    MessageView(message: message)
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Run") {
    VStack {
        RunView(run: mock_run)
    }
    .frame(width: 400, height: 400)
}


#Preview("Run Steps") {
    VStack {
        RunStepsView(messages: mock_run.steps)
    }
    .frame(width: 400, height: 400)
}
