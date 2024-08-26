import SwiftUI
import SwiftData
import HeatKit

struct MemoryList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
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
    }
    
    func handleSave(_ text: String) {
        let memory = Memory(content: text)
        modelContext.insert(memory)
    }
    
    func handleDelete(_ memory: Memory) {
        modelContext.delete(memory)
    }
}
