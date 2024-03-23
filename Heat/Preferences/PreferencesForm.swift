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
                TextField("Introduction", text: Binding(
                    get: { store.preferences.instructions ?? "" },
                    set: { store.preferences.instructions = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
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
                Picker("Chats", selection: Binding(
                    get: { store.preferences.preferredChatServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredChatServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsChats }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Images", selection: Binding(
                    get: { store.preferences.preferredImageServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredImageServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsImages }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Embeddings", selection: Binding(
                    get: { store.preferences.preferredEmbeddingServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredEmbeddingServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsEmbeddings }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Transcriptions", selection: Binding(
                    get: { store.preferences.preferredTranscriptionServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredTranscriptionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsTranscriptions }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Tools", selection: Binding(
                    get: { store.preferences.preferredToolServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredToolServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsTools }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Vision", selection: Binding(
                    get: { store.preferences.preferredVisionServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredVisionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsVision }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Speech", selection: Binding(
                    get: { store.preferences.preferredSpeechServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredSpeechServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsSpeech }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Summarization", selection: Binding(
                    get: { store.preferences.preferredSummarizationServiceID?.rawValue ?? "" },
                    set: { store.preferences.preferredSummarizationServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services.filter { $0.supportsSummarization }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
            } footer: {
                Text("Only services with preferred models selected to support the behavior will show up in the picker.")
            }
            
            Section {
                Button("Set Defaults", action: handleSetDefaults)
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
    
    func handleSetDefaults() {
        store.preferences.preferredChatServiceID = .openAI
        store.preferences.preferredImageServiceID = .openAI
        store.preferences.preferredEmbeddingServiceID = .openAI
        store.preferences.preferredTranscriptionServiceID = .openAI
        store.preferences.preferredToolServiceID = .openAI
        store.preferences.preferredVisionServiceID = .openAI
        store.preferences.preferredSpeechServiceID = .openAI
        store.preferences.preferredSummarizationServiceID = .openAI
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
