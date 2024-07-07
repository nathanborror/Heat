import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
    @State private var token: String = ""
    @State private var host: String = ""
    @State private var isShowingAlert = false
    @State private var error: PreferencesError? = nil
    
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
                Picker("Chats", selection: $service.preferredChatModel) {
                    serviceModelPickerView
                }
                Picker("Images", selection: $service.preferredImageModel) {
                    serviceModelPickerView
                }
                Picker("Embeddings", selection: $service.preferredEmbeddingModel) {
                    serviceModelPickerView
                }
                Picker("Transcriptions", selection: $service.preferredTranscriptionModel) {
                    serviceModelPickerView
                }
                Picker("Tools", selection: $service.preferredToolModel) {
                    serviceModelPickerView
                }
                Picker("Vision", selection: $service.preferredVisionModel) {
                    serviceModelPickerView
                }
                Picker("Speech", selection: $service.preferredSpeechModel) {
                    serviceModelPickerView
                }
                Picker("Summarization", selection: $service.preferredSummarizationModel) {
                    serviceModelPickerView
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
    }
    
    var serviceModelPickerView: some View {
        Group {
            Text("None").tag(String?.none)
            Divider()
            ForEach(service.models.sorted { $0.id < $1.id }) { model in
                Text(model.id).tag(model.id)
            }
        }
    }
    
    func handleSave() {
        if service.name.isEmpty {
            error = .missingName
            isShowingAlert = true
            return
        }
        handleApplyCredentials()
        Task { try await preferencesProvider.upsert(service: service) }
        dismiss()
    }
    
    func handleSetDefaults() {
        handleLoadModels()
        
        switch service.id {
        case .openAI:
            service.applyPreferredModels(Constants.openAIDefaults)
        case .anthropic:
            service.applyPreferredModels(Constants.anthropicDefaults)
        case .mistral:
            service.applyPreferredModels(Constants.mistralDefaults)
        case .perplexity:
            service.applyPreferredModels(Constants.perplexityDefaults)
        case .google:
            service.applyPreferredModels(Constants.googleDefaults)
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
