import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    @Environment(\.dismiss) private var dismiss
    
    @State var service: Service
    
    @State private var showingAdditionalServices = false
    
    private var showSelections: Bool {
        !service.models.isEmpty
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $service.name)
                    .disabled(true)
                
                TextField("Host", text: $service.host)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .submitLabel(.next)
                    .onSubmit { handleSetDefaults() }
                
                TextField("Token", text: $service.token)
                    .autocorrectionDisabled()
                    #if !os(macOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .submitLabel(.next)
                    .onSubmit { handleSetDefaults() }
            }
            
            Section {
                if showSelections {
                    ModelPicker("Chats", models: service.models, selection: $service.preferredChatModel)
                    ModelPicker("Images", models: service.models, selection: $service.preferredImageModel)
                    ModelPicker("Vision", models: service.models, selection: $service.preferredVisionModel)
                    ModelPicker("Summarization", models: service.models, selection: $service.preferredSummarizationModel)
                    
                    if showingAdditionalServices {
                        ModelPicker("Tools", models: service.models, selection: $service.preferredToolModel)
                        ModelPicker("Embeddings", models: service.models, selection: $service.preferredEmbeddingModel)
                        ModelPicker("Transcriptions", models: service.models, selection: $service.preferredTranscriptionModel)
                        ModelPicker("Speech", models: service.models, selection: $service.preferredSpeechModel)
                    } else {
                        Button {
                            showingAdditionalServices = true
                        } label: {
                            Text("Additional services")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No models", systemImage: "network")
                    } description: {
                        Text("Models will show up here after successfully connecting to the service.")
                    }
                }
            } header: {
                Text("Model Selection")
            }
            
            if showSelections {
                Section {
                    Button(action: handleLoadModels) {
                        Text("Load Models")
                    }
                }
            }
        }
        .appFormStyle()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Service")
        .onChange(of: service.token) { _, _ in
            handleLoadModels()
        }
        .onAppear {
            handleLoadModels()
        }
        .onDisappear {
            handleSave()
        }
    }
    
    func handleSave() {
        Task { try await preferencesProvider.upsert(service: service) }
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
            // Save any changes before loading models
            try await preferencesProvider.upsert(service: service)
            
            // Load models
            let client = service.modelService()
            let models = try await client.models()
            service.models = models
        }
    }
}

struct ModelPicker: View {
    let title: String
    let models: [Model]
    
    @Binding var selection: String?
    
    @State private var selectedModel: Model? = nil
    
    init(_ title: String, models: [Model], selection: Binding<String?>) {
        self.title = title
        self.models = models
        self._selection = selection
        
        if let selection = selection.wrappedValue {
            self.selectedModel = models.first(where: { $0.id == selection })
        }
    }
    
    var modelsByFamily: [String: [Model]] {
        Dictionary(grouping: models) { model in
            model.family ?? model.id
        }
    }
    
    var body: some View {
        Menu {
            Button {
                selectedModel = nil
                selection = nil
            } label: {
                Text("None")
            }
            Divider()
            ForEach(modelsByFamily.keys.sorted(), id: \.self) { family in
                if let familyModels = modelsByFamily[family] {
                    if familyModels.count > 1 {
                        Menu(family) {
                            ForEach(familyModels) { model in
                                menuItem(model: model)
                            }
                        }
                    } else if let model = familyModels.first {
                        menuItem(model: model)
                    }
                }
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                Group {
                    if let selectedModel {
                        Text(selectedModel.name ?? selectedModel.id)
                    } else {
                        Text("Select Model")
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary)
    }
    
    func menuItem(model: Model) -> some View {
        Button {
            selectedModel = model
            selection = model.id
        } label: {
            HStack {
                Text(model.name ?? model.id)
                if selectedModel?.id == model.id {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
