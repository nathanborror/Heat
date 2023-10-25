import SwiftUI
import HeatKit

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
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
            
            Button(role: .destructive, action: handleDeleteAll) {
                Text("Delete All Data")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: { dismiss() })
            }
        }
    }
    
    func handleDone() {
        dismiss()
    }
    
    func handleDeleteAll() {
        Task { try store.deleteAll() }
        dismiss()
    }
}
