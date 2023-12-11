import SwiftUI
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
                TextField("Tagline", text: $agent.tagline)
            }
            
            ForEach($agent.messages) { message in
                Section {
                    Picker("Role", selection: message.role) {
                        Text("System").tag(Message.Role.system)
                        Text("Assistant").tag(Message.Role.assistant)
                        Text("User").tag(Message.Role.user)
                    }
                    TextField("Content", text: message.content, axis: .vertical)
                }
            }
            
            Section {
                Button("Add Message", action: handleAddMessage)
            }
        }
        .navigationTitle("Create Agent")
        #if os(iOS)
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
        Task { await store.upsert(agent: agent) }
        dismiss()
    }
    
    func handleAddMessage() {
        var message: Message!
        if let lastMessage = agent.messages.last {
            switch lastMessage.role {
            case .system:
                message = Message(kind: .instruction, role: .assistant)
            case .assistant:
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
