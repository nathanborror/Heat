import SwiftUI
import GenKit
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent = .empty
    @State var messages: [(String, String)] = []
    
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
            
            ForEach($messages.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $messages[index].0) {
                        Text("System").tag(Message.Role.system)
                        Text("Assistant").tag(Message.Role.assistant)
                        Text("User").tag(Message.Role.user)
                    }
                    TextField("Content", text: $messages[index].1, axis: .vertical)
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
        .onAppear {
            messages = agent.messages.map { ($0.role.rawValue, $0.content ?? "") }
        }
    }
    
    func handleDone() {
        agent.messages = messages.map {
            .init(kind: .instruction, role: .init(rawValue: $0.0)!, content: $0.1)
        }
        store.upsert(agent: agent)
        dismiss()
    }
    
    func handleAddMessage() {
        var message: (String, String)
        if let lastMessage = agent.messages.last {
            switch lastMessage.role {
            case .system:
                message = (Message.Role.assistant.rawValue, "")
            case .assistant, .tool:
                message = (Message.Role.user.rawValue, "")
            case .user:
                message = (Message.Role.assistant.rawValue, "")
            }
        } else {
            message = (Message.Role.system.rawValue, "")
        }
        messages.append(message)
    }
}

#Preview {
    AgentForm(agent: .empty)
        .environment(Store.preview)
}
