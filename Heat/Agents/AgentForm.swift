import SwiftUI
import GenKit
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $agent.name)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                TextField("Tagline", text: Binding<String>(
                    get: { agent.tagline ?? "" },
                    set: { agent.tagline = $0.isEmpty ? nil : $0 }
                ))
            }
            
            ForEach($agent.messages.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $agent.messages[index].role) {
                        Text("System").tag(Message.Role.system)
                        Text("Assistant").tag(Message.Role.assistant)
                        Text("User").tag(Message.Role.user)
                    }

                    // Custom binding for handling optional string
                    TextField("Content", text: Binding<String>(
                        get: { self.agent.messages[index].content ?? "" },
                        set: { self.agent.messages[index].content = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                }
            }
            
            Section {
                Button("Add Message", action: handleAddMessage)
            }
        }
        .navigationTitle("Create Agent")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
    }
    
    func handleDone() {
        store.upsert(agent: agent)
        dismiss()
    }
    
    func handleAddMessage() {
        var message: Message!
        if let lastMessage = agent.messages.last {
            switch lastMessage.role {
            case .system:
                message = Message(kind: .instruction, role: .assistant)
            case .assistant, .tool:
                message = Message(kind: .instruction, role: .user)
            case .user:
                message = Message(kind: .instruction, role: .assistant)
            }
        } else {
            message = Message(kind: .instruction, role: .system)
        }
        agent.messages.append(message)
    }
}

#Preview {
    AgentForm(agent: .empty)
        .environment(Store.preview)
}
