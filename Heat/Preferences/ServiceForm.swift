import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
    @State private var isShowingAlert = false
    @State private var error: PreferencesError? = nil
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $service.name)
                    .disabled(true)
                TextField("Host", text: $service.host)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    .submitLabel(.next)
                    .onSubmit { handleSetDefaults() }
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
                TextField("Token", text: $service.token)
                    .submitLabel(.next)
                    .onSubmit { handleSetDefaults() }
            }
            
            Section {
                Button(action: handleSetDefaults) {
                    Text("Set Defaults")
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
            } header: {
                Text("Model Selection")
            }
            
            Section {
                Button(action: handleLoadModels) {
                    Text("Reload Models")
                }
            }
        }
        .appFormStyle()
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
        Task { try await preferencesProvider.upsert(service: service) }
        dismiss()
    }
    
    func handleSetDefaults() {
        handleLoadModels()
        
        switch service.id {
        case .openAI:
            service.applyPreferredModels(Defaults.openAI)
        case .anthropic:
            service.applyPreferredModels(Defaults.anthropic)
        case .mistral:
            service.applyPreferredModels(Defaults.mistral)
        case .perplexity:
            service.applyPreferredModels(Defaults.perplexity)
        case .google:
            service.applyPreferredModels(Defaults.google)
        default:
            break
        }
    }
    
    func handleLoadModels() {
        Task {
            do {
                let client = service.modelService()
                let models = try await client.models()
                service.models = models
            } catch {
                print(error)
            }
        }
    }
}
