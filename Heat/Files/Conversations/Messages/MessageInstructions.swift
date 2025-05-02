import SwiftUI
import HeatKit

struct MessageInstructions: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    let file: File
    let action: (String, [String: String], Set<String>) -> Void

    @State private var instructions = ""
    @State private var context: [String: String] = [:]
    @State private var toolIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(Array(context.keys), id: \.self) { key in
                    TextField(key,
                        text: Binding(
                            get: { context[key] ?? "" },
                            set: { context[key] = $0 }
                        ),
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.primary.opacity(0.05))
                    .clipShape(.rect(cornerRadius: 10))
                }

                Text(instructions)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(maxHeight: 400)
        .navigationTitle("Instructions")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    handleSubmit()
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            handleLoad()
        }
    }

    func handleLoad() {
        do {
            let instruction = try state.file(Instruction.self, fileID: file.id)
            context = instruction.context
            instructions = instruction.instructions
            toolIDs = instruction.toolIDs
        } catch {
            state.log(error: error)
        }
    }

    func handleSubmit() {
        action(instructions, context, toolIDs)
    }
}
