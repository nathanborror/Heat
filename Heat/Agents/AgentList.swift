import SwiftUI
import HeatKit

struct AgentList: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let action: (String) -> Void

    @State private var isShowingAgentForm = false
    @State private var agent: Agent = .empty
    
    var body: some View {
        List {
            Section {
                Button("New Agent") {
                    isShowingAgentForm = true
                }
            }
            Section {
                ForEach(store.agents) { agent in
                    Button(agent.name) {
                        handleSelection(agent.id)
                    }
                }
            }
        }
        .navigationTitle("Agents")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
        .sheet(isPresented: $isShowingAgentForm) {
            NavigationStack {
                AgentForm(agent: $agent)
            }.environment(store)
        }
    }
    
    func handleSelection(_ agentID: String) {
        action(agentID)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AgentList() {_ in}
    }.environment(Store.preview)
}
