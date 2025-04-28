import SwiftUI
import GenKit
import HeatKit

struct ServiceOnboarding: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var serviceID: Service.ServiceID = .openAI
    @State var serviceAPIKey: String = ""
    @State var serviceModels: [Model] = []
    @State var serviceModelID: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                Spacer()
                Image("HomeIcon")
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
                    Text("DeepSeek").tag(Service.ServiceID.deepseek)
                    Text("Grok").tag(Service.ServiceID.grok)
                    Text("Groq").tag(Service.ServiceID.groq)
                    Text("Mistral").tag(Service.ServiceID.mistral)
                    Text("Ollama").tag(Service.ServiceID.ollama)
                    Text("OpenAI").tag(Service.ServiceID.openAI)
                    Text("Perplexity").tag(Service.ServiceID.perplexity)
                }

                // Hide API Key when Ollama is selected because it doesn't require one.
                if serviceID != Service.ServiceID.ollama {
                    TextField("API Key", text: $serviceAPIKey)
                }

                // Only show models when Ollama is selected and models are loaded.
                if serviceID == Service.ServiceID.ollama && !serviceModels.isEmpty {
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
                Button("Continue", action: handleContinue)
                        .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 340)
        .onChange(of: serviceID) { oldValue, newValue in
            handleServiceChange()
        }
        .onAppear {
            handleServiceChange()
        }
    }

    func handleServiceChange() {
        let env = ProcessInfo.processInfo.environment
        switch serviceID {
        case .anthropic:
            serviceAPIKey = env["ANTHROPIC_API_KEY"] ?? serviceAPIKey
        case .deepseek:
            serviceAPIKey = env["DEEPSEEK_API_KEY"] ?? serviceAPIKey
        case .grok:
            serviceAPIKey = env["GROK_API_KEY"] ?? serviceAPIKey
        case .groq:
            serviceAPIKey = env["GROQ_API_KEY"] ?? serviceAPIKey
        case .mistral:
            serviceAPIKey = env["MISTRAL_API_KEY"] ?? serviceAPIKey
        case .ollama:
            Task { serviceModels = try await prepareModels(serviceID.rawValue) }
        case .openAI:
            serviceAPIKey = env["OPENAI_API_KEY"] ?? serviceAPIKey
        case .perplexity:
            serviceAPIKey = env["PERPLEXITY_API_KEY"] ?? serviceAPIKey
        default:
            break
        }
    }

    func handleOpenPreferences() {
        // dismiss the dialog and openURL that opens the preferences sheet
    }

    func handleContinue() {
        Task {
            do {
                // Establish preferred models to use from the service
                // Since these are hard-coded they could become out-of-dated
                var preferredChatModel = ""
                var preferredSummarizationModel = ""
                switch serviceID {
                case .anthropic:
                    preferredChatModel = .init("claude-3-5-sonnet")
                    preferredSummarizationModel = .init("claude-3-5-haiku")
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
                case .perplexity:
                    preferredChatModel = .init("llama-3.1-sonar-large-128k-chat")
                    preferredSummarizationModel = .init("llama-3.1-sonar-small-128k-chat")
                default:
                    return
                }

                var config = API.shared.config

                // Update the service settings
                if let index = config.services.firstIndex(where: { $0.id == serviceID.rawValue }) {
                    var existing = config.services[index]
                    existing.token = serviceAPIKey
                    existing.preferredChatModel = preferredChatModel
                    existing.preferredSummarizationModel = preferredSummarizationModel
                    config.services[index] = existing
                }

                // Set preferred service and save preferences
                config.serviceChatDefault = serviceID.rawValue
                config.serviceSummarizationDefault = serviceID.rawValue
                try await API.shared.configUpdate(config)

                dismiss()
            } catch {
                print(error)
            }
        }
    }

    private func prepareModels(_ serviceID: String) async throws -> [Model] {
        print("not implemented"); return []
//        // Initialize fetches the latest models and updates the service status
//        try await state.configProvider.initialize(serviceID: serviceID)
//
//        // Return the service's models
//        let service = try state.configProvider.get(serviceID: serviceID)
//        return service.models
    }
}
