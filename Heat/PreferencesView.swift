import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "PreferencesView", category: "Heat")

struct PreferencesView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool
    
    var body: some View {
        @Bindable var store = store
        
        Form {
            Section {
                TextField("Host Address", text: Binding<String>(
                        get: { store.preferences.host?.absoluteString ?? "" },
                        set: { store.preferences.host = URL(string: $0) }
                    )
                )
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
        guard let url = store.preferences.host else {
            logger.warning("missing ollama host url")
            return
        }
        Task {
            await ModelManager(url: url, models: store.models)
                .refresh()
                .sink { store.upsert(models: $0) }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
    }.environment(Store.preview)
}
