import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
    @State private var token: String = ""
    @State private var host: String = ""
    @State private var isShowingAlert = false
    @State private var error: PreferencesError? = nil
    
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
                TextField("Name", text: $service.name)
                TextField("Host", text: $host)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
                TextField("Token", text: $token)
            }
            
            Section {
                Button(action: handleSetDefaults) {
                    Text("Set Defaults")
                }
                Button(action: handleLoadModels) {
                    Text("Reload Models")
                }
            }
            
            Section {
                Picker("Chats", selection: $service.preferredChatModel ?? "") {
                    servicePickerModels
                }
                Picker("Images", selection: $service.preferredImageModel ?? "") {
                    servicePickerModels
                }
                Picker("Embeddings", selection: $service.preferredEmbeddingModel ?? "") {
                    servicePickerModels
                }
                Picker("Transcriptions", selection: $service.preferredTranscriptionModel ?? "") {
                    servicePickerModels
                }
                Picker("Tools", selection: $service.preferredToolModel ?? "") {
                    servicePickerModels
                }
                Picker("Vision", selection: $service.preferredVisionModel ?? "") {
                    servicePickerModels
                }
                Picker("Speech", selection: $service.preferredSpeechModel ?? "") {
                    servicePickerModels
                }
            } footer: {
                Text("Preferred models to use.")
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        .frame(width: 400)
        .frame(minHeight: 450)
        #endif
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Service")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
        .alert(isPresented: $isShowingAlert, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                error = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
        .onAppear {
            handleLoadCredentials()
            handleLoadModels()
        }
        .onDisappear {
            handleSave()
        }
    }
    
    func handleSave() {
        if service.name.isEmpty {
            error = .missingName
            isShowingAlert = true
            return
        }
        handleApplyCredentials()
        store.upsert(service: service)
        dismiss()
    }
    
    func handleSetDefaults() {
        handleLoadModels()
        
        switch service.id {
        case .openAI:
            service.applyDefaults(defaults: Constants.openAIDefaults)
        case .anthropic:
            service.applyDefaults(defaults: Constants.anthropicDefaults)
        case .mistral:
            service.applyDefaults(defaults: Constants.mistralDefaults)
        case .perplexity:
            service.applyDefaults(defaults: Constants.perplexityDefaults)
        case .google:
            service.applyDefaults(defaults: Constants.googleDefaults)
        default:
            break
        }
    }
    
    func handleLoadModels() {
        handleApplyCredentials()
        Task {
            do {
                let client = try service.modelService()
                let models = try await client.models()
                service.models = models
            } catch {
                print(error)
            }
        }
    }
    
    func handleLoadCredentials() {
        if let credentials = service.credentials {
            switch credentials {
            case .host(let host):
                self.host = host.absoluteString
            case .token(let token):
                self.token = token
            }
        }
    }
    
    func handleApplyCredentials() {
        switch (token.isEmpty, host.isEmpty) {
        case (false, true):
            service.credentials = .token(token)
        case (true, false):
            service.credentials = .host(URL(string: host)!)
        case (false, false):
            print("not implemented")
        default:
            service.credentials = nil
        }
    }
}

extension Service {
    
    mutating func applyDefaults(defaults service: Service) {
        self.preferredChatModel = service.preferredChatModel
        self.preferredImageModel = service.preferredImageModel
        self.preferredEmbeddingModel = service.preferredEmbeddingModel
        self.preferredTranscriptionModel = service.preferredTranscriptionModel
        self.preferredToolModel = service.preferredToolModel
        self.preferredVisionModel = service.preferredVisionModel
        self.preferredSpeechModel = service.preferredSpeechModel
    }
}

#Preview {
    NavigationStack {
        ServiceForm(service: .init(id: .mistral, name: "Mistral"))
    }
    .environment(Store.preview)
}
