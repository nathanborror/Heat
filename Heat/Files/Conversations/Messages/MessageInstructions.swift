import SwiftUI
import HeatKit

struct MessageInstructions: View {
    @Environment(\.dismiss) var dismiss

    @State var instruction: Instruction
    let action: (Instruction) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(Array(instruction.context.keys), id: \.self) { key in
                    TextField(key,
                        text: Binding(
                            get: { instruction.context[key] ?? "" },
                            set: { instruction.context[key] = $0 }
                        ),
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 10))
                }

                Text(instruction.instructions)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxHeight: 400)
        .navigationTitle(instruction.name)
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
        action(instruction)
    }
}
