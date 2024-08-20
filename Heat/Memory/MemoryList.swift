import SwiftUI
import SwiftData
import HeatKit

struct MemoryList: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]

    @State private var newMemoryContent = ""
    @State private var isCreatingMemory = false
    
    var body: some View {
        List {
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
        .navigationTitle("Memories")
        .toolbar {
            ToolbarItem {
                Button(action: { isCreatingMemory = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreatingMemory) {
            NavigationStack {
                Form {
                    TextField("Memory contents", text: $newMemoryContent, axis: .vertical)
                }
                .navigationTitle("New Memory")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: handleSave) {
                            Text("Done")
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { isCreatingMemory = false }) {
                            Text("Cancel")
                        }
                    }
                }
            }
        }
    }
    
    func handleSave() {
        guard !newMemoryContent.isEmpty else {
            return
        }
        let memory = Memory(content: newMemoryContent)
        modelContext.insert(memory)
        
        // Reset and dismiss
        newMemoryContent = ""
        isCreatingMemory = false
    }
    
    func handleDelete(_ memory: Memory) {
        modelContext.delete(memory)
    }
}
