import SwiftUI
import HeatKit

struct PreferencesView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool
    
    var bindingForHost: Binding<String> {
        Binding<String>(
            get: {
                store.preferences.host?.absoluteString ?? ""
            },
            set: {
                store.preferences.host = URL(string: $0)
            }
        )
    }
    
    var body: some View {
        @Bindable var store = store
        
        Form {
            Section {
                TextField("Host Address", text: bindingForHost)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } header: {
                Text("Host")
            } footer: {
                Text(verbatim: "Example: http://localhost:8080")
            }
            
            Section {
                Picker("Current Model", selection: $store.preferences.preferredModelID) {
                    Text("None").tag("")
                    ForEach(store.models) { model in
                        Text(model.name).tag(model.id)
                    }
                }
                NavigationLink("Models") {
                    ModelList()
                }
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
                Button("Done", action: handleDone)
            }
        }
        .refreshable {
            handleLoadModels()
        }
        .onChange(of: store.preferences.host) { _, _ in
            store.resetClients()
        }
        .onAppear {
            handleLoadModels()
        }
    }
    
    func handleDone() {
        handleLoadModels()
        dismiss()
    }
    
    func handleDeleteAll() {
        Task {
            try store.deleteAll()
            try await store.saveAll()
        }
        dismiss()
    }
    
    func handleResetAgents() {
        Task {
            store.resetAgents()
            try await store.saveAll()
        }
        dismiss()
    }
    
    func handleLoadModels() {
        Task { try await store.modelsLoad() }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }.environment(Store.preview)
}
