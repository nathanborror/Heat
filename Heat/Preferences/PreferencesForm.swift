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
                Picker("Default Agent", selection: $preferences.defaultAgentID) {
                    Text("None").tag(String?.none)
                    Divider()
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
                Toggle("Stream", isOn: $preferences.shouldStream)
                Toggle("Markdown", isOn: $preferences.shouldUseMarkdown)
                Toggle("Debug", isOn: $preferences.debug)
            }
            
            Section {
                Picker("Chats", selection: $preferences.preferred.chatServiceID) {
                    servicePickerView(\.supportsChats)
                }
                Picker("Images", selection: $preferences.preferred.imageServiceID) {
                    servicePickerView(\.supportsImages)
                }
                Picker("Embeddings", selection: $preferences.preferred.embeddingServiceID) {
                    servicePickerView(\.supportsEmbeddings)
                }
                Picker("Transcriptions", selection: $preferences.preferred.transcriptionServiceID) {
                    servicePickerView(\.supportsTranscriptions)
                }
                Picker("Tools", selection: $preferences.preferred.toolServiceID) {
                    servicePickerView(\.supportsTools)
                }
                Picker("Vision", selection: $preferences.preferred.visionServiceID) {
                    servicePickerView(\.supportsVision)
                }
                Picker("Speech", selection: $preferences.preferred.speechServiceID) {
                    servicePickerView(\.supportsSpeech)
                }
                Picker("Summarization", selection: $preferences.preferred.summarizationServiceID) {
                    servicePickerView(\.supportsSummarization)
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
    
    func servicePickerView(_ prop: KeyPath<Service, Bool>) -> some View {
        Group {
            Text("None").tag(Service.ServiceID?.none)
            Divider()
            ForEach(preferencesProvider.services.filter { $0[keyPath: prop] }) { service in
                Text(service.name).tag(service.id)
            }
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
