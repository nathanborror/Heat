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

struct MemoryForm: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var text: String = ""
    
    let action: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextField("Content", text: $text)
                .focused($isFocused)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            handleSubmit()
                        } label: {
                            Text("Done")
                        }
                    }
                }
        }
        #if os(macOS)
        .formStyle(.grouped)
        .frame(width: 400)
        .frame(minHeight: 450)
        #endif
        .onAppear {
            isFocused = true
        }
    }
    
    func handleSubmit() {
        action(text.trimmingCharacters(in: .whitespacesAndNewlines))
        text = ""
        dismiss()
    }
}
