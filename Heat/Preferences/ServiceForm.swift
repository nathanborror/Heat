import SwiftUI
import GenKit
import HeatKit

struct ServiceForm: View {
    @Environment(AppState.self) var state
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

                Button {
                    handleSetDefaults()
                } label: {
                    Text("Load Models")
                }
                #if os(macOS)
                .buttonStyle(.link)
                #endif
                .disabled(service.host.isEmpty && service.token.isEmpty)
            }

            Section {
                if showSelections {
                    ModelPicker("Chats", models: service.models, selection: $service.preferredChatModel)
                    ModelPicker("Images", models: service.models, selection: $service.preferredImageModel)
                    ModelPicker("Summarization", models: service.models, selection: $service.preferredSummarizationModel)

                    if showingAdditionalServices {
                        ModelPicker("Embeddings", models: service.models, selection: $service.preferredEmbeddingModel)
                        ModelPicker("Transcriptions", models: service.models, selection: $service.preferredTranscriptionModel)
                        ModelPicker("Speech", models: service.models, selection: $service.preferredSpeechModel)
                    } else {
                        Button {
                            showingAdditionalServices = true
                        } label: {
                            Text("Additional services")
                        }
                        #if os(macOS)
                        .buttonStyle(.link)
                        #endif
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
        }
        .appFormStyle()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Service")
        .onChange(of: service.token) { _, _ in
            Task { try await handleInitializeService() }
        }
        .onAppear {
            Task { try await handleInitializeService() }
        }
        .onDisappear {
            handleSave()
        }
    }

    func handleSave() {
        Task { try await state.preferencesProvider.upsert(service: service) }
    }

    func handleSetDefaults() {
        Task {
            try await handleInitializeService()

            service = try state.preferencesProvider.get(serviceID: service.id)

            switch service.id {
            case .openAI:
                service.applyPreferredModels(Defaults.openAI)
            case .anthropic:
                service.applyPreferredModels(Defaults.anthropic)
            case .mistral:
                service.applyPreferredModels(Defaults.mistral)
            case .perplexity:
                service.applyPreferredModels(Defaults.perplexity)
            default:
                break
            }
        }
    }

    func handleInitializeService() async throws {
        // Save any changes before loading models
        try await state.preferencesProvider.upsert(service: service)

        // Initialize
        try await state.preferencesProvider.initialize(serviceID: service.id)
    }
}

struct ModelPicker: View {
    let title: String
    let models: [Model]

    @Binding var selection: String?

    init(_ title: String, models: [Model], selection: Binding<String?>) {
        self.title = title
        self.models = models
        self._selection = selection
    }

    var modelsByFamily: [String: [Model]] {
        Dictionary(grouping: models) { model in
            model.family ?? model.id
        }
    }

    var body: some View {
        LabeledContent(title) {
            Menu {
                Button {
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
                Group {
                    if let selection, let model = models.first(where: { $0.id == selection }) {
                        Text(model.name ?? model.id)
                    } else {
                        HStack {
                            Text("Select Model")
                            Image(systemName: "chevron.up.chevron.down")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .menuStyle(.button)
        }
    }

    func menuItem(model: Model) -> some View {
        Button {
            selection = model.id
        } label: {
            HStack {
                Text(model.name ?? model.id)
                if let selection, selection == model.id {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
