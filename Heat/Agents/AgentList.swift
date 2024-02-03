import SwiftUI
import HeatKit

struct AgentList: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingAgentForm = false
    
    var body: some View {
        List {
            Section {
                ForEach(store.agents) { agent in
                    NavigationLink(agent.name) {
                        AgentForm(agent: agent)
                    }
                    .swipeActions {
                        Button(role: .destructive, action: { handleDeleteAgent(agent) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Agents")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { isShowingAgentForm = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAgentForm) {
            NavigationStack {
                AgentForm(agent: .empty)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingAgentForm = false }
                        }
                    }
            }.environment(store)
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
