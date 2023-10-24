import SwiftUI
import HeatKit

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
    @Binding var preferences: Preferences
    
    @State var modelToPull = ""
    @State var modelPullStatus: String? = nil
    
    var body: some View {
        Form {
            Section {
                Picker("Model Name", selection: $preferences.model) {
                    ForEach(store.models, id:\.name) { model in
                        Text(model.name).tag(model.name)
                    }
                }
            } header: {
                Text("Model")
            }
            
            Section {
                TextField("Host Address", text: $preferences.host)
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
                TextField("Model Name", text: $modelToPull)
                if let status = modelPullStatus {
                    Text(status)
                }
                Button(action: handleModelPull) {
                    Text("Pull Model")
                }
            } header: {
                Text("Pull Model")
            }
            
            Button(role: .destructive, action: handleDeleteAll) {
                Text("Delete All Data")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            handleLoadModels()
        }
    }
    
    func handleLoadModels() {
        Task {
            try await store.models()
        }
    }
    
    func handleDeleteAll() {
        Task { try store.deleteAll() }
        dismiss()
    }
    
    func handleModelPull() {
        Task(priority: .background) {
            let name = modelToPull
            try await store.modelPull(name: name) { progress in
                DispatchQueue.main.async {
                    modelPullStatus = progress.status
                }
            }
            modelPullStatus = nil
        }
    }
}
