import SwiftUI
import HeatKit

struct MemoryList: View {
    @Environment(AppState.self) var state

    @State var memories: [Memory] = []

    var body: some View {
        Form {
            Section {
                NavigationLink("New Memory") {
                    MemoryForm { handleSave($0) }
                }
            }
            Section {
                ForEach(memories) { memory in
                    Text(memory.content)
                        .swipeActions {
                            Button(role: .destructive) {
                                handleDelete(memory)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .appFormStyle()
        .navigationTitle("Memories")
        .overlay {
            if memories.isEmpty {
                ContentUnavailableView {
                    Label("Memories about you", systemImage: "brain")
                } description: {
                    Text("No memories yet.")
                }
            }
        }
        .onAppear {
            handleLoad()
        }
    }

    func handleLoad() {
        Task {
            do {
                let memories = try await state.memoryProvider.get()
                self.memories = memories
            } catch {
                print(error)
            }
        }
    }

    func handleSave(_ text: String) {
        print("not implemented")
    }

    func handleDelete(_ memory: Memory) {
        Task { try await state.memoryProvider.delete(memory.id) }
    }
}
