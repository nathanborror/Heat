import SwiftUI
import HeatKit

struct AgentList: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAgent: Agent = .empty
    @State private var isShowingAgentForm = false
    
    var body: some View {
        Form {
            Section {
                Button("Create Agent") {
                    selectedAgent = .empty
                    isShowingAgentForm = true
                }
            }
            Section {
                ForEach(store.agents) { agent in
                    Button(agent.name) {
                        selectedAgent = agent
                        isShowingAgentForm = true
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive, action: { handleDeleteAgent(agent) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Agents")
        .sheet(isPresented: $isShowingAgentForm) {
            NavigationStack {
                AgentForm(agent: selectedAgent)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingAgentForm = false }
                        }
                    }
            }
            .environment(store)
            .frame(width: 400, height: 400)
        }
    }
    
    func handleDeleteAgent(_ agent: Agent) {
        store.delete(agentID: agent.id)
    }
}

#Preview {
    NavigationStack {
        AgentList()
    }.environment(Store.preview)
}
