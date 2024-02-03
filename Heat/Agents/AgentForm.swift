import SwiftUI
import PhotosUI
import GenKit
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    @State var instructions: [(String, String)] = []
    
    var body: some View {
        Form {
            Section {
                AgentPictureButton(picture: agent.picture)
            }
            .listRowBackground(Color.clear)
            
            Section {
                TextField("Name", text: $agent.name)
            }
            
            ForEach($instructions.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $instructions[index].0) {
                        Text("System").tag("system")
                        Text("Assistant").tag("assistant")
                        Text("User").tag("user")
                    }
                    TextField("Content", text: $instructions[index].1, axis: .vertical)
                }
                .swipeActions {
                    Button(role: .destructive, action: { handleDeleteInstruction(index) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            Section {
                Button("Add Instruction", action: handleAddInstruction)
            }
        }
        .navigationTitle("Agent")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
        }
        .onAppear {
            instructions = agent.instructions.map { ($0.role.rawValue, $0.content ?? "") }
        }
    }
    
    private func handleDone() {
        agent.instructions = instructions
            .filter({ !$0.1.isEmpty })
            .map {
                Message(kind: .instruction, role: .init(rawValue: $0.0)!, content: $0.1)
            }
        store.upsert(agent: agent)
        dismiss()
    }
    
    private func handleAddInstruction() {
        if let last = instructions.last {
            switch last.0 {
            case "system", "user":
                instructions.append(("assistant", ""))
            case "assistant":
                instructions.append(("user", ""))
            default:
                instructions.append(("system", ""))
            }
        } else {
            instructions.append(("system", ""))
        }
    }
    
    private func handleDeleteInstruction(_ index: Int) {
        instructions.remove(at: index)
    }
}

struct AgentPictureButton: View {
    let picture: Asset?
    
    var body: some View {
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let picture {
                        PictureView(asset: picture)
                    } else {
                        Rectangle()
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Squircle())
                
                Image(systemName: "pencil")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .background(.tint)
                    .clipShape(.circle)
                    .offset(x: 4, y: 4)
            }
            Spacer()
        }
    }
}

#Preview("Create Agent") {
    NavigationStack {
        AgentForm(agent: .empty)
    }.environment(Store.preview)
}

#Preview("Edit Agent") {
    let store = Store.preview
    let agent = Agent.preview
    
    return NavigationStack {
        AgentForm(agent: agent)
    }.environment(store)
}
