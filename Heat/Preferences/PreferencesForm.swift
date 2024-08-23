import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PreferencesForm: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @Environment(\.dismiss) private var dismiss
    
    @State var preferences: Preferences
    
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        Form {
            #if !os(macOS)
            Section {
                NavigationLink("Memories") {
                    MemoryList()
                }
            }
            #endif
                        
            Section {
                #if !os(macOS)
                NavigationLink("Agents") {
                    AgentList()
                }
                #endif
                Picker("Default Agent", selection: $preferences.defaultAgentID ?? "") {
                    ForEach(agentsProvider.agents) { agent in
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
                    get: { preferences.preferred.chatServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.chatServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsChats }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Images", selection: Binding(
                    get: { preferences.preferred.imageServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.imageServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsImages }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Embeddings", selection: Binding(
                    get: { preferences.preferred.embeddingServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.embeddingServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsEmbeddings }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Transcriptions", selection: Binding(
                    get: { preferences.preferred.transcriptionServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.transcriptionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsTranscriptions }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Tools", selection: Binding(
                    get: { preferences.preferred.toolServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.toolServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsTools }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Vision", selection: Binding(
                    get: { preferences.preferred.visionServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.visionServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsVision }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Speech", selection: Binding(
                    get: { preferences.preferred.speechServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.speechServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsSpeech }) { service in
                        Text(service.name).tag(service.id.rawValue)
                    }
                }
                Picker("Summarization", selection: Binding(
                    get: { preferences.preferred.summarizationServiceID?.rawValue ?? "" },
                    set: { preferences.preferred.summarizationServiceID = Service.ServiceID(rawValue: $0) }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(preferencesProvider.services.filter { $0.supportsSummarization }) { service in
                        Text(service.name).tag(service.id.rawValue)
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
        .onDisappear {
            handleSave()
        }
    }
    
    func handleAgentReset() {
        Task {
            try await agentsProvider.reset()
        }
    }
    
    func handleDeleteAll() {
        Task {
            try await agentsProvider.reset()
            try await conversationsProvider.reset()
            try await preferencesProvider.reset()
            
            preferences = preferencesProvider.preferences
        }
    }
    
    func handleSave() {
        Task {
            try await preferencesProvider.upsert(preferences)
        }
    }
}

struct PreferencesWindow: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(ConversationsProvider.self) var conversationsProvider
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @State var selection = Tabs.general
    
    enum Tabs: Hashable {
        case general, services, agents, permissions, memories
    }
    
    var body: some View {
        TabView(selection: $selection) {
            PreferencesForm(preferences: preferencesProvider.preferences)
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
            MemoryList()
                .padding(20)
                .frame(width: 400)
                .tag(Tabs.memories)
                .tabItem {
                    Label("Memories", systemImage: "brain")
                }
        }
        .frame(minHeight: 450, alignment: .top)
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
