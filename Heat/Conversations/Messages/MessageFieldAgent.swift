import SwiftUI
import HeatKit

struct MessageFieldAgent: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    let action: (Agent) -> Void
    
    var body: some View {
        Form {
            Section {
                ForEach(Array(agent.context.keys), id: \.self) { key in
                    VStack {
                        TextField(key, text: Binding(
                            get: { agent.context[key] ?? "" },
                            set: { agent.context[key] = $0 }
                        ))
                    }
                }
            }
            
            TextField("Instructions", text: $agent.instructions, axis: .vertical)
        }
        .appFormStyle()
        .navigationTitle(agent.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    handleSubmit()
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
    }
    
    func handleSubmit() {
        action(agent)
    }
}
