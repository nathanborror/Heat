import SwiftUI
import HeatKit

struct PreferencesView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool
    
    var body: some View {
        @Bindable var store = store
        
        Form {
            Section {
                TextField("Host Address", text: $store.preferences.host)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("Host")
            } footer: {
                Text("Example: 127.0.0.1:8080")
            }
            
            Section {
                Picker("Model", selection: $store.preferences.preferredModelID) {
                    Text("None").tag("")
                    ForEach(store.models) { model in
                        Text(model.name).tag(model.id)
                    }
                }
            } header: {
                Text("Preferred Model")
            }
            
            Section {
                ForEach(store.models) { model in
                    NavigationLink {
                        ModelView(modelID: model.id)
                    } label: {
                        Text(model.name)
                    }
                }
                Button("Reload Models") {
                    handelLoadModels()
                }
            } header: {
                Text("Models")
            }
            
            Section {
                Toggle("Debug Mode", isOn: $store.preferences.isDebug)
                Toggle("Show Suggestions", isOn: $store.preferences.isSuggesting)
            }
            
            Section {
                Button(action: handleResetAgents) {
                    Text("Reset Agents")
                }
                Button(role: .destructive, action: handleDeleteAll) {
                    Text("Delete All Data")
                }
            }
        }
        .formStyle(.grouped)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Settings")
        .frame(idealWidth: 400, idealHeight: 400)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDismiss)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: handleDismiss)
            }
        }
        .onChange(of: store.preferences.host) { _, _ in
            store.resetClients()
        }
        .onAppear {
            handelLoadModels()
        }
    }
    
    func handleDismiss() {
        dismiss()
    }
    
    func handleDeleteAll() {
        Task {
            try await store.deleteAll()
            try await store.saveAll()
        }
        handleDismiss()
    }
    
    func handleResetAgents() {
        Task {
            try await store.resetAgents()
            try await store.saveAll()
        }
        handleDismiss()
    }
    
    func handelLoadModels() {
        Task {
            try await store.modelsLoad()
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }.environment(Store.preview)
}
