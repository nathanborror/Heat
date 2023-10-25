import SwiftUI
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
    @State var name = ""
    @State var tagline = ""
    @State var system = ""
    @State var modelID: String? = nil
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    ModelListView(modelID: $modelID)
                } label: {
                    HStack {
                        if let model = model {
                            Text("Model")
                            Spacer()
                            Text(model.name)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Model Name")
                        }
                    }
                }
                if let model = model {
                    NavigationLink {
                        ModelView(modelID: model.id)
                    } label: {
                        Text("Model Details")
                    }
                }
            } header: {
                Text("Model")
            }
            
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
    
    var model: Model? {
        guard let modelID = modelID else { return nil }
        return store.get(modelID: modelID)
    }
    
    func handleDone() {
        guard let modelID = modelID else { return }
        let agent = store.createAgent(modelID: modelID, name: name, tagline: tagline, system: system)
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
