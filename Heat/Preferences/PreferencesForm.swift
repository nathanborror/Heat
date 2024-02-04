import SwiftUI
import SharedKit
import GenKit
import HeatKit

enum PreferencesError: LocalizedError {
    case missingID
    case missingName
    case unsavedChanges
    
    var errorDescription: String? {
        switch self {
        case .missingID: "Missing ID"
        case .missingName: "Missing name"
        case .unsavedChanges: "Unsaved changes"
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .missingID: "Enter an identifier for the service."
        case .missingName: "Enter a name for the service."
        case .unsavedChanges: "You have unsaved changes, do you want to discard them?"
        }
    }
}

struct PreferencesForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var models: [Model] = []
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                TextField("Introduction", text: $store.preferences.instructions ?? "", axis: .vertical)
            } footer: {
                Text("Personalize your experience by describing who you are.")
            }
            
            Section {
                #if !os(macOS)
                NavigationLink("Agents") {
                    AgentList()
                }
                #endif
                Picker("Default Agent", selection: $store.preferences.defaultAgentID ?? "") {
                    ForEach(store.agents) { agent in
                        Text(agent.name).tag(agent.id)
                    }
                }
            } footer: {
                Text("Used to start new conversations.")
            }
            
            #if !os(macOS)
            Section {
                NavigationLink("Services") {
                    ServiceList()
                }
            } footer: {
                Text("Manage service configurations like preferred models, authentication tokens and API endpoints.")
            }
            #endif
            
            Section {
                Picker("Chats", selection: $store.preferences.preferredChatServiceID ?? "") {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsChats {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Images", selection: $store.preferences.preferredImageServiceID ?? "") {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsImages {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Embeddings", selection: $store.preferences.preferredEmbeddingServiceID ?? "") {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsEmbeddings {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Transcriptions", selection: $store.preferences.preferredTranscriptionServiceID ?? "") {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsTranscriptions {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
            } footer: {
                Text("Only services with preferred models selected to support the behavior will show up in the picker.")
            }
            
            Section {
                Button("Reset Agents", action: handleAgentReset)
                Button("Delete All Data", role: .destructive, action: { isShowingDeleteConfirmation = true })
            }
        }
        .navigationTitle("Preferences")
        .alert("Are you sure?", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: handleDeleteAll)
        } message: {
            Text("This will delete all app data and preferences.")
        }
    }
    
    func handleAgentReset() {
        do {
            try store.resetAgents()
            Task { try await store.saveAll() }
            dismiss()
        } catch {
            print(error)
        }
    }
    
    func handleDeleteAll() {
        store.deleteAll()
        dismiss()
    }
}

struct PreferencesWindow: View {
    @Environment(Store.self) private var store
    
    @State var selection = "general"
    
    var body: some View {
        TabView(selection: $selection) {
            PreferencesForm()
                .padding(20)
                .frame(width: 400)
                .tag("general")
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            ServiceList()
                .padding(20)
                .frame(width: 400)
                .tag("services")
                .tabItem {
                    Label("Services", systemImage: "cloud")
                }
            AgentList()
                .padding(20)
                .frame(width: 400)
                .tag("agents")
                .tabItem {
                    Label("Agents", systemImage: "person.crop.rectangle.stack")
                }
        }
    }
}

#Preview("Form") {
    NavigationStack {
        PreferencesForm()
    }
    .environment(Store.preview)
}

#Preview("Window") {
    NavigationStack {
        PreferencesWindow()
    }
    .environment(Store.preview)
}
