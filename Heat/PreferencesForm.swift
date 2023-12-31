import SwiftUI
import GenKit
import HeatKit

struct PreferencesForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var preferences: Preferences
    @State private var models: [Model] = []
    @State private var isLoadingModels = false
    
    var body: some View {
        Form {
            Section {
                Picker("Service", selection: $preferences.service) {
                    Text("Pick Service")
                        .tag("")
                        .disabled(true)
                    Divider()
                    ForEach(Preferences.Service.allCases) {
                        Text($0.title).tag($0)
                    }
                }
                
                switch preferences.service {
                case .openai:
                    TextField("OpenAI Token", text: Binding<String>(
                            get: { preferences.token ?? "" },
                            set: { preferences.token = $0 }
                        )
                    )
                    .onSubmit {
                        handleLoadModels()
                    }
                case .ollama:
                    TextField("Ollama URL", text: Binding<String>(
                            get: { preferences.host?.absoluteString ?? "" },
                            set: { preferences.host = URL(string: $0) }
                        )
                    )
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit {
                        handleLoadModels()
                    }
                case .mistral:
                    TextField("Mistral Token", text: Binding<String>(
                            get: { preferences.token ?? "" },
                            set: { preferences.token = $0 }
                        )
                    )
                    .onSubmit {
                        handleLoadModels()
                    }
                case .perplexity:
                    TextField("Perplexity Token", text: Binding<String>(
                            get: { preferences.token ?? "" },
                            set: { preferences.token = $0 }
                        )
                    )
                    .onSubmit {
                        handleLoadModels()
                    }
                }
            } header: {
                Text("Service Provider")
            }
            
            if isLoadingModels {
                Section {
                    Text("Loading Models...")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Default Model")
                }
            }
            
            if !models.isEmpty {
                Section {
                    Picker("Model", selection: Binding<String>(
                            get: { preferences.model ?? "" },
                            set: { preferences.model = $0 }
                        )
                    ) {
                        Text("Pick Model")
                            .tag("")
                            .disabled(true)
                        Divider()
                        ForEach(models.sorted { $0.id < $1.id }) { model in
                            Text(model.id).tag(model.id)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                } header: {
                    Text("Default Model")
                }
            }
            
            Section {
                Button("Reset", role: .destructive) {
                    handleReset()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Preferences")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .interactiveDismissDisabled()
        .frame(idealWidth: 400, idealHeight: 400)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
        .refreshable {
            handleLoadModels()
        }
        .onChange(of: preferences.service) { _, _ in
            models = []
            preferences.model = nil
            handleLoadModels()
        }
        .onAppear {
            handleLoadModels()
        }
    }
    
    private func handleLoadModels() {
        let service: ModelService
        switch preferences.service {
        case .openai:
            guard let token = preferences.token else { return }
            service = OpenAIService(token: token)
        case .ollama:
            guard let url = preferences.host else { return }
            service = OllamaService(url: url)
        case .mistral:
            guard let token = preferences.token else { return }
            service = MistralService(token: token)
        case .perplexity:
            guard let token = preferences.token else { return }
            service = PerplexityService(token: token)
        }
        Task {
            isLoadingModels = true
            self.models = try await service.models()
            isLoadingModels = false
        }
    }
    
    private func handleDone() {
        store.preferences = preferences
        Task { try await store.saveAll() }
        dismiss()
    }
    
    private func handleReset() {
        store.resetAll()
        Task { try await store.saveAll() }
        dismiss()
    }
}

#Preview {
    let store = Store.preview
    return NavigationStack {
        PreferencesForm(preferences: store.preferences)
    }.environment(store)
}
