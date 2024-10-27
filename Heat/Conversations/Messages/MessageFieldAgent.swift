import SwiftUI
import HeatKit

struct MessageFieldAgent: View {
    @Environment(\.dismiss) private var dismiss

    @State var agent: Agent
    let action: (Agent) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(Array(agent.context.keys), id: \.self) { key in
                    TextField(key,
                        text: Binding(
                            get: { agent.context[key] ?? "" },
                            set: { agent.context[key] = $0 }
                        ),
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 10))
                }

                Text(agent.instructions)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxHeight: 400)
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
