import SwiftUI
import PhotosUI
import GenKit
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @Binding var agent: Agent
    
    var body: some View {
        Form {
            Section {
                AgentPictureButton(picture: agent.picture)
            }
            .listRowBackground(Color.clear)
            
            Section {
                TextField("Name", text: $agent.name)
            }
            
            ForEach($agent.instructions.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $agent.instructions[index].role) {
                        Text("System").tag(Message.Role.system)
                        Text("Assistant").tag(Message.Role.assistant)
                        Text("User").tag(Message.Role.user)
                    }
                    TextField("Content", text: Binding<String>(
                        get: { agent.instructions[index].content ?? "" },
                        set: { agent.instructions[index].content = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }
                .swipeActions {
                    Button(role: .destructive, action: { handleDeleteMessage(agent.instructions[index]) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            Section {
                Button("Add Message", action: handleAddMessage)
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
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
    }
    
    private func handleDone() {
        store.upsert(agent: agent)
        dismiss()
    }
    
    private func handleAddMessage() {
        var message: Message!
        if let lastMessage = agent.instructions.last {
            switch lastMessage.role {
            case .system, .user, .tool:
                message = Message(kind: .instruction, role: .assistant)
            case .assistant:
                message = Message(kind: .instruction, role: .user)
            }
        } else {
            message = Message(kind: .instruction, role: .system)
        }
        agent.instructions.append(message)
    }
    
    private func handleDeleteMessage(_ message: Message) {
        agent.instructions.removeAll(where: { $0.id == message.id })
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
        AgentForm(agent: .constant(.empty))
    }.environment(Store.preview)
}

#Preview("Edit Agent") {
    let store = Store.preview
    let agent = Agent.preview
    
    return NavigationStack {
        AgentForm(agent: .constant(agent))
    }.environment(store)
}
