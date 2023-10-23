import SwiftUI
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
    @State var name = ""
    @State var tagline = ""
    @State var system = ""
    @State var preferredModel = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
            } header: {
                Text("Name")
            }
            
            Section {
                TextField("Tagline", text: $tagline)
            } header: {
                Text("Tagline")
            }
            
            Section {
                TextField("System Prompt", text: $system, axis: .vertical)
            } header: {
                Text("System Prompt")
            }
            
            Section {
                Picker("Preferred Model", selection: $preferredModel) {
                    Text("None").tag("")
                    ForEach(store.models, id:\.name) { model in
                        Text(model.name).tag(model.name)
                    }
                }
            } header: {
                Text("Model")
            }
        }
        .navigationTitle("Create Agent")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: { dismiss() })
            }
        }
        .onAppear {
            handleLoadModels()
        }
    }
    
    func handleDone() {
        let agent = store.createAgent(name: name, tagline: tagline, preferredModel: preferredModel.isEmpty ? nil : preferredModel, system: system)
        Task { await store.upsert(agent: agent) }
        dismiss()
    }
    
    func handleLoadModels() {
        Task { try await store.models() }
    }
}

#Preview {
    NavigationStack {
        AgentForm()
    }.environment(Store.shared)
}
