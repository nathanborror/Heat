import SwiftUI
import HeatKit

struct PreferencesView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var store = store
        
        Form {
            Section {
                TextField("Host Address", text: $store.preferences.host)
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
            
            Button(action: handleResetAgents) {
                Text("Reset Agents")
            }
            .buttonStyle(.plain)
            
            Button(role: .destructive, action: handleDeleteAll) {
                Text("Delete All Data")
            }
            .buttonStyle(.plain)
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
