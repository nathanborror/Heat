import SwiftUI
import HeatKit

struct PreferencesView: View {
    @Environment(Store.self) private var store
    
    @State var router: MainRouter
    
    var body: some View {
        @Bindable var store = store
        
        RoutingView(router: router) {
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
                    Button("Cancel", action: { router.dismiss() })
                }
            }
        }
    }
    
    func handleDone() {
        router.dismiss()
    }
    
    func handleDeleteAll() {
        Task {
            try await store.deleteAll()
            try await store.saveAll()
        }
        router.dismiss()
    }
    
    func handleResetAgents() {
        Task {
            try await store.resetAgents()
            try await store.saveAll()
        }
        router.dismiss()
    }
}
