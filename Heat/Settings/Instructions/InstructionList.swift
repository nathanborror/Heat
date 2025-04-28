import SwiftUI
import HeatKit

struct InstructionList: View {
    @Environment(AppState.self) var state

    @Binding var selection: String?

    @State var instructions: [Instruction] = []

    var body: some View {
        List(selection: $selection) {
            ForEach(instructions) { instruction in
                Text(instruction.name)
                    .tag(instruction.id)
            }
        }
        .navigationTitle("Instructions")
    }
}
