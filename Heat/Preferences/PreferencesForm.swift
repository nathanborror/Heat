import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PreferencesForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var preferences: Preferences
    
    @State private var models: [Model] = []
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        Form {
            Section {
                TextField("Introduction", text: Binding(
                    get: { preferences.instructions ?? "" },
                    set: { preferences.instructions = $0.isEmpty ? nil : $0 }
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
                Picker("Default Agent", selection: $preferences.defaultAgentID ?? "") {
                    ForEach(AgentStore.shared.agents) { agent in
                        Text(agent.name).tag(agent.id)
                    }
                }
            } footer: {
                Text("Used to start new conversations.")
            }
            
            #if !os(macOS)
            Section {
                NavigationLink("Model Services") {
                    ServiceList()
                }
                NavigationLink("Permissions") {
                    PermissionsList()
                }
            } footer: {
                Text("Manage service configurations and permissions to external data sources.")
            }
            #endif
            
            Section {
                Toggle("Stream responses", isOn: $preferences.shouldStream)
                Toggle("Debug", isOn: $preferences.debug)
            }
            
            Section {
                Picker("Chats", selection: Binding(
                    get: { preferences.preferredChatServiceID?.rawValue ?? "" },
                    set: { preferences.preferredChatServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsChats }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Images", selection: Binding(
                    get: { preferences.preferredImageServiceID?.rawValue ?? "" },
                    set: { preferences.preferredImageServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsImages }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Embeddings", selection: Binding(
                    get: { preferences.preferredEmbeddingServiceID?.rawValue ?? "" },
                    set: { preferences.preferredEmbeddingServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsEmbeddings }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Transcriptions", selection: Binding(
                    get: { preferences.preferredTranscriptionServiceID?.rawValue ?? "" },
                    set: { preferences.preferredTranscriptionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsTranscriptions }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Tools", selection: Binding(
                    get: { preferences.preferredToolServiceID?.rawValue ?? "" },
                    set: { preferences.preferredToolServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsTools }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Vision", selection: Binding(
                    get: { preferences.preferredVisionServiceID?.rawValue ?? "" },
                    set: { preferences.preferredVisionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsVision }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Speech", selection: Binding(
                    get: { preferences.preferredSpeechServiceID?.rawValue ?? "" },
                    set: { preferences.preferredSpeechServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsSpeech }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Summarization", selection: Binding(
                    get: { preferences.preferredSummarizationServiceID?.rawValue ?? "" },
                    set: { preferences.preferredSummarizationServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferences.services.filter { $0.supportsSummarization }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
            } footer: {
                Text("Only services with preferred models selected to support the behavior will show up in the picker.")
            }
            
            Section {
                Button("Reset Services", action: handleServicesReset)
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
        print("not implemented")
    }
    
    func handleServicesReset() {
        preferences.preferredChatServiceID = .openAI
        preferences.preferredImageServiceID = .openAI
        preferences.preferredEmbeddingServiceID = .openAI
        preferences.preferredTranscriptionServiceID = .openAI
        preferences.preferredToolServiceID = .openAI
        preferences.preferredVisionServiceID = .openAI
        preferences.preferredSpeechServiceID = .openAI
        preferences.preferredSummarizationServiceID = .openAI
        handleSave()
    }
    
    func handleDeleteAll() {
        print("not implemented")
    }
    
    func handleSave() {
        Task { try await store.saveAll() }
    }
}

struct PreferencesWindow: View {
    @Environment(Store.self) private var store
    
    @State var selection = Tabs.general
    
    enum Tabs: Hashable {
        case general, services, agents, permissions
    }
    
    var body: some View {
        TabView(selection: $selection) {
            PreferencesForm(preferences: PreferencesStore.shared.preferences)
                .padding(20)
                .frame(width: 400)
                .tag(Tabs.general)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            ServiceList()
                .padding(20)
                .frame(width: 400)
                .tag(Tabs.services)
                .tabItem {
                    Label("Services", systemImage: "cloud")
                }
            AgentList()
                .padding(20)
                .frame(width: 400)
                .tag(Tabs.agents)
                .tabItem {
                    Label("Agents", systemImage: "network")
                }
            PermissionsList()
                .padding(20)
                .frame(width: 400)
                .tag(Tabs.permissions)
                .tabItem {
                    Label("Permissions", systemImage: "hand.raised")
                }
        }
    }
}

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
