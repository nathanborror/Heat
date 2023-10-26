import SwiftUI
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    
    @State var agent: Agent
    @State var router: MainRouter
    
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
                TextField("Tagline", text: $agent.tagline)
            } header: {
                Text("Tagline")
            }
            
            Section {
                TextField("System Prompt", text: $agent.system ?? "", axis: .vertical)
            } header: {
                Text("System Prompt")
            }
        }
        .navigationTitle("Create Agent")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
        }
        .onAppear {
            handleLoadModels()
        }
    }
    
    func handleDone() {
        Task { await store.upsert(agent: agent) }
        router.dismiss()
    }
    
    func handleLoadModels() {
        Task {
            try await store.loadModels()
            try await store.loadModelDetails()
        }
    }
}
