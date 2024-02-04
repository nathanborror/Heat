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
                    HStack {
                        Text(agent.name)
                        Spacer()
                        Button("Edit") {
                            selectedAgent = agent
                            isShowingAgentForm = true
                        }
                        #if os(macOS)
                        Button(action: { handleDeleteAgent(agent) }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        #endif
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
        .sheet(isPresented: $isShowingAgentForm) {
            NavigationStack {
                AgentForm(agent: selectedAgent)
            }
            .environment(store)
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
