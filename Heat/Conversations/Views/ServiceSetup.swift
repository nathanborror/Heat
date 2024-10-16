import SwiftUI
import GenKit
import HeatKit

struct ServiceSetup: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @State var serviceID: Service.ServiceID = .openAI
    @State var serviceAPIKey: String = ""
    @State var serviceModels: [Model] = []
    @State var serviceModelID: String? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                Spacer()
                Image("IconDesktop")
                    .resizable()
                    .frame(width: 64, height: 64)
                Spacer()
            }
            
            VStack(spacing: 16) {
                Text("Welcome to Heat")
                    .font(.headline)
                Text("Pick a Chat Service and provide an API key. For Ollama there's no need for an API key but you will need to pick an installed model to use.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true) // Prevents occasional word truncation
            }
            
            VStack {
                Picker("Service", selection: $serviceID) {
                    Text("Anthropic").tag(Service.ServiceID.anthropic)
                    Text("Groq").tag(Service.ServiceID.groq)
                    Text("Mistral").tag(Service.ServiceID.mistral)
                    Text("Ollama").tag(Service.ServiceID.ollama)
                    Text("OpenAI").tag(Service.ServiceID.openAI)
                }
                
                // Hide API Key when Ollama is selected because it doesn't require one.
                if serviceID != .ollama {
                    TextField("API Key", text: $serviceAPIKey)
                        .textFieldStyle(.roundedBorder)
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
            }
            .labelsHidden()
            
            HStack {
                Spacer()
                Button("Open Preferences", action: handleOpenPreferences)
                Button("Continue", action: { Task { try await handleContinue() }})
                        .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 340)
        .onChange(of: serviceID) { oldValue, newValue in
            handleServiceChange()
        }
    }
    
    func handleServiceChange() {
        guard serviceID == .ollama else { return }
        Task { serviceModels = try await prepareModels(serviceID) }
    }
    
    func handleOpenPreferences() {
        // dismiss the dialog and openURL that opens the preferences sheet
    }
    
    func handleContinue() async throws {
        
        // Set API token for service
        try await preferencesProvider.upsert(token: serviceAPIKey, serviceID: serviceID)
        
        // Establish preferred models to use from the service
        // Since these are hard-coded they could become out-of-dated
        var preferredChatModel = ""
        var preferredSummarizationModel = ""
        switch serviceID {
        case .anthropic:
            preferredChatModel = "claude-3-5-sonnet-20240620"
            preferredSummarizationModel = "claude-3-haiku-20240307"
        case .groq:
            preferredChatModel = "llama-3.1-70b-versatile"
            preferredSummarizationModel = "llama-3.1-8b-instant"
        case .mistral:
            preferredChatModel = "mistral-large-latest"
            preferredSummarizationModel = "mistral-small-latest"
        case .ollama:
            preferredChatModel = serviceModelID ?? "llama3.2"
            preferredSummarizationModel = serviceModelID ?? "llama3.2"
        case .openAI:
            preferredChatModel = "gpt-4o"
            preferredSummarizationModel = "gpt-4o-mini"
        default:
            return
        }
        
        // Set preferred models on service
        var service = try preferencesProvider.get(serviceID: serviceID)
        service.preferredChatModel = preferredChatModel
        service.preferredSummarizationModel = preferredSummarizationModel
        try await preferencesProvider.upsert(service: service)

        // Set preferred service and save preferences
        var preferences = preferencesProvider.preferences
        preferences.preferred.chatServiceID = serviceID
        preferences.preferred.summarizationServiceID = serviceID
        try await preferencesProvider.upsert(preferences)
        
        dismiss()
    }
    
    private func prepareModels(_ serviceID: Service.ServiceID) async throws -> [Model] {
        let service = try preferencesProvider.get(serviceID: serviceID)
        let modelService = service.modelService()
        let models =  try await modelService.models()
        
        // Save models for service
        try await preferencesProvider.upsert(models: models, serviceID: serviceID)
        
        return models
    }
}
