import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
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
                TextField("Identifier", text: $service.id)
                TextField("Name", text: $service.name)
                TextField("Host", text: Binding<String>(
                    get: { service.host?.absoluteString ?? "" },
                    set: { service.host = ($0.isEmpty) ? nil : URL(string: $0) }
                ))
                .autocorrectionDisabled()
                .textContentType(.URL)
                #if !os(macOS)
                .textInputAutocapitalization(.never)
                #endif
                
                TextField("Token", text: $service.token ?? "")
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
            
            Section {
                Button(action: handleLoadModels) {
                    Text("Reload Models")
                }
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        .frame(width: 400)
        .frame(minHeight: 450)
        #endif
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
        dismiss()
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
            case "elevenlabs":
                guard let token = service.token else { return }
                client = ElevenLabsService(configuration: .init(token: token))
            case "google":
                guard let token = service.token else { return }
                client = GoogleService(configuration: .init(token: token))
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
}

#Preview {
    NavigationStack {
        ServiceForm(service: .init(id: "", name: ""))
    }
    .environment(Store.preview)
}
