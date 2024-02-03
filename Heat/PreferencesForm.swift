import SwiftUI
import SharedKit
import GenKit
import HeatKit

struct PreferencesForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var models: [Model] = []
    @State private var isShowingDeleteConfirmation = false
    
    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                TextField("Describe yourself", text: $store.preferences.instructions ?? "", axis: .vertical)
            } header: {
                Text("Instructions")
            } footer: {
                Text("Personalize your experience by describing who you are.")
            }
            
            Section {
                NavigationLink("Agents") {
                    AgentList()
                }
                Picker("Default Agent", selection: $store.preferences.defaultAgentID ?? "") {
                    ForEach(store.agents) { agent in
                        Text(agent.name).tag(agent.id)
                    }
                }
            } header: {
                Text("Agents")
            }
            
            Section {
                Picker("Chats", selection: Binding<String>(
                    get: { store.preferences.preferredChatServiceID ?? "" },
                    set: { store.preferences.preferredChatServiceID = $0 }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsChats {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Images", selection: Binding<String>(
                    get: { store.preferences.preferredImageServiceID ?? "" },
                    set: { store.preferences.preferredImageServiceID = $0 }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsImages {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Embeddings", selection: Binding<String>(
                    get: { store.preferences.preferredEmbeddingServiceID ?? "" },
                    set: { store.preferences.preferredEmbeddingServiceID = $0 }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsEmbeddings {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
                Picker("Transcriptions", selection: Binding<String>(
                    get: { store.preferences.preferredTranscriptionServiceID ?? "" },
                    set: { store.preferences.preferredTranscriptionServiceID = $0 }
                )) {
                    Text("None").tag("")
                    Divider()
                    ForEach(store.preferences.services) { service in
                        if service.supportsTranscriptions {
                            Text(service.name).tag(service.id)
                        }
                    }
                }
            } header: {
                Text("Services")
            } footer: {
                Text("Only services with preferred models selected to support the behavior will show up in the picker.")
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
                Button("Reset Agents", action: handleAgentReset)
                Button("Delete All Data", role: .destructive, action: { isShowingDeleteConfirmation = true })
            }
        }
        .formStyle(.grouped)
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

struct ServiceList: View {
    @Environment(Store.self) private var store
    
    @State private var service: Service? = nil
    
    var body: some View {
        Form {
            ForEach(store.preferences.services) { service in
                NavigationLink {
                    ServiceForm(service: service)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(service.name)
                            if let text = supportText(for: service) {
                                Text(text)
                                    .lineLimit(1)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if service.missingHost {
                                Text("Host missing")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            if service.missingToken {
                                Text("Token missing")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            Section {
                Button("Add Service", action: { self.service = .init(id: "", name: "") })
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Services")
        .sheet(item: $service) { service in
            NavigationStack {
                ServiceForm(service: service)
            }.environment(store)
        }
    }
    
    func supportText(for service: Service) -> String? {
        let supports = [
            (service.supportsChats) ? "Chats" : nil,
            (service.supportsImages) ? "Images" : nil,
            (service.supportsEmbeddings) ? "Embeddings" : nil,
            (service.supportsTranscriptions) ? "Transcriptions" : nil,
        ].compactMap { $0 }
        if supports.isEmpty { return nil }
        return supports.joined(separator: ", ")
    }
}

struct ServiceForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
    @State private var isShowingAlert = false
    @State private var error: ServiceFormError? = nil
    
    var servicePickerModels: some View {
        Group {
            Text("None").tag("")
            Divider()
            ForEach(service.models.sorted { $0.id < $1.id }) { model in
                Text(model.id).tag(model.id)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                LabeledContent("ID") {
                    TextField("Add identifier", text: $service.id)
                }
                LabeledContent("Name") {
                    TextField("Add name", text: $service.name)
                }
                LabeledContent("Host") {
                    TextField("Add host", text: Binding<String>(
                            get: { service.host?.absoluteString ?? "" },
                            set: { service.host = URL(string: $0) }
                        )
                    )
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                }
                LabeledContent("Token") {
                    TextField("Add token", text: Binding<String>(
                            get: { service.token ?? "" },
                            set: { service.token = $0 }
                        )
                    )
                }
            }
            .labeledContentStyle(BalancedLabelStyle())
            
            Section {
                Picker("Chats", selection: Binding<String>(
                    get: { service.preferredChatModel ?? "" },
                    set: { service.preferredChatModel = $0 }
                )) {
                    servicePickerModels
                }
                Picker("Images", selection: Binding<String>(
                    get: { service.preferredImageModel ?? "" },
                    set: { service.preferredImageModel = $0 }
                )) {
                    servicePickerModels
                }
                Picker("Embeddings", selection: Binding<String>(
                    get: { service.preferredEmbeddingModel ?? "" },
                    set: { service.preferredEmbeddingModel = $0 }
                )) {
                    servicePickerModels
                }
                Picker("Transcriptions", selection: Binding<String>(
                    get: { service.preferredTranscriptionModel ?? "" },
                    set: { service.preferredTranscriptionModel = $0 }
                )) {
                    servicePickerModels
                }
            } header: {
                Text("Preferred Models")
            }
            
            Section {
                Button(action: handleLoadModels) {
                    Text("Reload Models")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Service")
        .alert(isPresented: $isShowingAlert, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                error = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
        .onAppear {
            handleLoadModels()
        }
        .onDisappear {
            handleSave()
        }
    }
    
    func handleSave() {
        if service.id.isEmpty {
            error = .missingID
            isShowingAlert = true
            return
        }
        if service.name.isEmpty {
            error = .missingName
            isShowingAlert = true
            return
        }
        store.upsert(service: service)
    }
    
    func handleLoadModels() {
        Task {
            var client: ModelService? = nil
            switch service.id {
            case "openai":
                guard let token = service.token else { return }
                client = OpenAIService(configuration: .init(token: token))
            case "ollama":
                guard let host = service.host else { return }
                client = OllamaService(configuration: .init(host: host))
            case "mistral":
                guard let token = service.token else { return }
                client = MistralService(configuration: .init(token: token))
            case "perplexity":
                guard let token = service.token else { return }
                client = PerplexityService(configuration: .init(token: token))
            default:
                return
            }
            do {
                guard let models = try await client?.models() else { return }
                service.models = models
            } catch {
                print(error)
            }
        }
    }
    
    enum ServiceFormError: LocalizedError {
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
}

struct BalancedLabelStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            HStack {
                configuration.label
                Spacer()
            }
            .frame(width: 60)
            configuration.content
        }
    }
}

struct PreferencesDesktopForm: View {
    @Environment(Store.self) private var store
    
    var body: some View {
        TabView {
            PreferencesForm()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")
            ServiceList()
                .tabItem {
                    Label("Services", systemImage: "gear")
                }
                .tag("services")
        }
    }
}

#Preview("Preferences") {
    let store = Store.preview
    return NavigationStack {
        PreferencesForm()
    }.environment(store)
}

#Preview("Services") {
    let store = Store.preview
    return NavigationStack {
        ServiceList()
    }.environment(store)
}

#Preview("Service") {
    let store = Store.preview
    return NavigationStack {
        ServiceForm(service: .init(id: "", name: ""))
    }.environment(store)
}
