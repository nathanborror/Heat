import SwiftUI
import HeatKit

struct InstructionList: View {
    @Environment(AppState.self) var state

    @Binding var selection: String?

    @State var instructions: [File] = []

    var body: some View {
        List(selection: $selection) {
            ForEach(instructions) { file in
                Text(file.name ?? "Untitled")
                    .tag(file.id)
            }
        }
        .navigationTitle("Instructions")
    }
}
