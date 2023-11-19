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
            } header: {
                Text("Models")
            }
            
            Toggle("Debug", isOn: $store.preferences.isDebug)
            
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
        .onChange(of: isFocused) { _, newValue in
            print("change: \(newValue)")
        }
        .onAppear {
            Task {
                try await store.modelsLoad()
            }
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
}

#Preview {
    NavigationStack {
        PreferencesView()
    }.environment(Store.preview)
}
