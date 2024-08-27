import SwiftUI
import HeatKit

struct ServiceNudge: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var apiKey = ""
    @State var hasPaseboardString = false
    
    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 12) {
            
            Text("Getting Started")
                .font(.headline)
            
            Text("Open Preferences to configure a Service like Ollama, Anthropic, Groq, Mistral and more.")
                .font(.subheadline)
                .multilineTextAlignment(textAlignment)
            
            Text("Or quickly get started using [OpenAI](https://platform.openai.com/api-keys):")
                .font(.subheadline)
                .multilineTextAlignment(textAlignment)
            
            HStack {
                TextField("OpenAI API Key", text: $apiKey)
                    .padding(verticalPadding)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { try await handleSubmit() }
                    }
                if hasPaseboardString {
                    Button(action: handleLoadPasteboard) {
                        Image(systemName: "list.clipboard")
                            .padding(.trailing, 12)
                            .padding(.bottom, 2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius).stroke(.primary.opacity(0.1), lineWidth: 1)
            }
            .padding(.horizontal, -12)
        }
        .padding(24)
        .onAppear {
            handleCheckPasteboard()
        }
    }
    
    func handleCheckPasteboard() {
        #if os(macOS)
        let contents = NSPasteboard.general.string(forType: .string) ?? apiKey
        apiKey = contents.hasPrefix("sk-") ? contents : ""
        #else
        hasPaseboardString = UIPasteboard.general.hasStrings
        #endif
    }
    
    func handleLoadPasteboard() {
        #if os(macOS)
        let contents = NSPasteboard.general.string(forType: .string) ?? apiKey
        #else
        let contents = UIPasteboard.general.string ?? apiKey
        #endif
        apiKey = contents.hasPrefix("sk-") ? contents : ""
    }
    
    func handleSubmit() async throws {
        guard !apiKey.isEmpty else { return }
        
        // Update service with token and preferred models
        var service = try PreferencesProvider.shared.get(serviceID: .openAI)
        service.applyPreferredModels(Defaults.openAI)
        service.credentials = .token(apiKey)
        try await PreferencesProvider.shared.upsert(service: service)
        
        // Update preferences with preferred services
        var preferences = PreferencesProvider.shared.preferences
        preferences.preferred.chatServiceID = .openAI
        preferences.preferred.imageServiceID = .openAI
        preferences.preferred.embeddingServiceID = .openAI
        preferences.preferred.transcriptionServiceID = .openAI
        preferences.preferred.toolServiceID = .openAI
        preferences.preferred.visionServiceID = .openAI
        preferences.preferred.speechServiceID = .openAI
        preferences.preferred.summarizationServiceID = .openAI
        
        // Upsert preference changes
        try await PreferencesProvider.shared.upsert(preferences)
        
        dismiss()
    }
    
    #if os(macOS)
    let verticalPadding: CGFloat = 8
    let cornerRadius: CGFloat = 6
    let iconSize: CGFloat = 48
    let horizontalAlignment: HorizontalAlignment = .center
    let textAlignment: TextAlignment = .center
    #else
    let verticalPadding: CGFloat = 12
    let cornerRadius: CGFloat = 10
    let iconSize: CGFloat = 54
    let horizontalAlignment: HorizontalAlignment = .leading
    let textAlignment: TextAlignment = .leading
    #endif
}

#Preview {
    ServiceNudge()
}
