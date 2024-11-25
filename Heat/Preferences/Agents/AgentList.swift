import SwiftUI
import HeatKit

struct AgentList: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                NavigationLink("Add Agent") {
                    AgentForm(agent: .empty)
                }
            }
            Section {
                ForEach(state.agentsProvider.agents) { agent in
                    NavigationLink(agent.name) {
                        AgentForm(agent: agent)
                    }
                    .swipeActions {
                        Button(role: .destructive, action: { handleDelete(agent) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Agents")
        .appFormStyle()
    }

    func handleDelete(_ agent: Agent) {
        Task { try await state.agentsProvider.delete(agent.id)}
    }
}
