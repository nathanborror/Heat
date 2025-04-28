import HeatKit
import SwiftUI

struct FileList: View {
    @Environment(AppState.self) var state

    @Binding var selected: String?

    var body: some View {
        List(selection: $selected) {
            Section {
                ForEach(state.files) { file in
                    Label(file.name ?? "Untitled", systemImage: "bubble")
                        .tag(file.id)
                }
            }
        }
//        OutlineGroup(state.fileTree, children: \.children) { ref in
//            if let file = try? API.shared.file(ref.id) {
//                Label(file.name ?? "Untitled", systemImage: "bubble")
//                    .tag(file.id)
//            }
//        }
        .listStyle(.sidebar)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("History")
        #if os(iOS)
        .onChange(of: selected) { _, newValue in
            if newValue != nil { dismiss() }
        }
        .overlay {
            if state.conversationsProvider.conversations.isEmpty {
                ContentUnavailableView {
                    Label("Conversation history", systemImage: "clock")
                } description: {
                    Text("Your history is empty.")
                }
            }
        }
        #endif
    }
}
