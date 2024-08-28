import SwiftUI
import HeatKit

struct AgentList: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Add Agent") {
                    AgentForm(agent: .empty)
                }
            }
            Section {
                ForEach(agentsProvider.agents) { agent in
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
        .appFormStyle()
    }
    
    func handleDeleteAgent(_ agent: Agent) {
        Task { try await agentsProvider.delete(agent.id)}
    }
}
