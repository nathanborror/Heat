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
            } header: {
                Text("Name")
            }
            
            Section {
                TextField("Prompt", text: $agent.prompt, axis: .vertical)
            } header: {
                Text("Prompt")
            }
        }
        .navigationTitle("Create Agent")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
        }
    }
    
    func handleDone() {
        Task { await store.upsert(agent: agent) }
        dismiss()
    }
}
