import SwiftUI
import GenKit
import HeatKit

struct ServiceOnboarding: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) private var dismiss

    @State var serviceID: Service.ServiceID = .ollama
    @State var serviceAPIKey: String = ""
    @State var serviceModels: [Model] = []
    @State var serviceModelID: String? = nil

    var body: some View {
        Form {
            Section {
                Picker("Service", selection: $serviceID) {
                    Text("Anthropic").tag(Service.ServiceID.anthropic)
                    Text("Groq").tag(Service.ServiceID.groq)
                    Text("Mistral").tag(Service.ServiceID.mistral)
                    Text("Ollama").tag(Service.ServiceID.ollama)
                    Text("OpenAI").tag(Service.ServiceID.openAI)
                    Text("Perplexity").tag(Service.ServiceID.perplexity)
                }

                // Hide API Key when Ollama is selected because it doesn't require one.
                TextField("API Key", text: $serviceAPIKey)
                    .disabled(serviceID == .ollama)
                    .onSubmit {
                        
                    }

                // Only show models when Ollama is selected and models are loaded.
                if serviceID == .ollama && !serviceModels.isEmpty {
                    Picker("Model", selection: $serviceModelID) {
                        Text("None").tag(String?.none)
                        Divider()
                        ForEach(serviceModels) { model in
                            Text(model.name ?? model.id).tag(model.id)
                        }
                    }
                }
            } footer: {
                Text("Pick a Chat Service and provide an API key. For Ollama there's no need for an API key but you will need to pick an installed model to use.")
            }
        }
        .navigationTitle("Pick Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    Task { try await handleContinue() }
                }
            }
        }
        .onChange(of: serviceID) { oldValue, newValue in
            handleServiceChange()
        }
        .onAppear {
            handleServiceChange()
        }
    }

    func handleServiceChange() {
        switch serviceID {
        case .anthropic:
            serviceAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? serviceAPIKey
        case .groq:
            serviceAPIKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? serviceAPIKey
        case .mistral:
            serviceAPIKey = ProcessInfo.processInfo.environment["MISTRAL_API_KEY"] ?? serviceAPIKey
        case .ollama:
            Task { serviceModels = try await prepareModels(serviceID) }
        case .openAI:
            serviceAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? serviceAPIKey
        case .perplexity:
            serviceAPIKey = ProcessInfo.processInfo.environment["PERPLEXITY_API_KEY"] ?? serviceAPIKey
        default:
            break
        }
    }

    func handleContinue() async throws {

        // Set API token for service
        try await state.preferencesProvider.upsert(token: serviceAPIKey, serviceID: serviceID.rawValue)
        try await state.preferencesProvider.initialize(serviceID: serviceID.rawValue)

        // Establish preferred models to use from the service
        // Since these are hard-coded they could become out-of-dated
        var preferredChatModel: String = .init("")
        var preferredSummarizationModel: String = .init("")

        switch serviceID {
        case .anthropic:
            preferredChatModel = .init("claude-3-7-sonnet-latest")
            preferredSummarizationModel = .init("claude-3-5-haiku-latest")
        case .groq:
            preferredChatModel = .init("llama-3.1-70b-versatile")
            preferredSummarizationModel = .init("llama-3.1-8b-instant")
        case .mistral:
            preferredChatModel = .init("mistral-large-latest")
            preferredSummarizationModel = .init("mistral-small-latest")
        case .ollama:
            preferredChatModel = serviceModelID ?? .init("llama3.2")
            preferredSummarizationModel = serviceModelID ?? .init("llama3.2")
        case .openAI:
            preferredChatModel = .init("gpt-4o")
            preferredSummarizationModel = .init("gpt-4o-mini")
        default:
            return
        }

        // Set preferred models on service
        var service = try state.preferencesProvider.get(serviceID: serviceID.rawValue)
        service.preferredChatModel = preferredChatModel
        service.preferredSummarizationModel = preferredSummarizationModel
        try await state.preferencesProvider.upsert(service: service)

        // Set preferred service and save preferences
        var preferences = state.preferencesProvider.preferences
        preferences.preferred.chatServiceID = serviceID.rawValue
        preferences.preferred.summarizationServiceID = serviceID.rawValue
        try await state.preferencesProvider.upsert(preferences)

        dismiss()
    }

    private func prepareModels(_ serviceID: Service.ServiceID) async throws -> [Model] {
        // Initialize fetches the latest models and updates the service status
        try await state.preferencesProvider.initialize(serviceID: serviceID.rawValue)

        // Return the service's models
        let service = try state.preferencesProvider.get(serviceID: serviceID.rawValue)
        return service.models
    }
}
