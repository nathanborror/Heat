import SwiftUI
import HeatKit

struct ConversationBarrier: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var apiKey = ""
    @State var hasPaseboardString = false
    
    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 24) {
            
            Image("IconDark")
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .padding(4)
                .background(.background)
                .clipShape(Squircle())
                .shadow(color: .primary.opacity(0.2), radius: 1, y: 1)
            
            // Copy
            VStack(alignment: horizontalAlignment, spacing: 8) {
                Text("Welcome to Heat")
                    .font(.body)
                    .fontWeight(.semibold)
                Text("Before getting started you need to provide an [OpenAI API key](https://platform.openai.com/api-keys). Other services can be configured under the Services tab in the Preferences pane.")
                    .font(.subheadline)
                    .multilineTextAlignment(textAlignment)
                    .foregroundStyle(.secondary)
            }
            
            // API key field
            HStack {
                TextField("Your API Key", text: $apiKey)
                    .padding(verticalPadding)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .onSubmit {
                        handleSubmit()
                    }
                if hasPaseboardString {
                    Button(action: handleLoadPasteboard) {
                        Image(systemName: "list.clipboard")
                            .padding(.trailing, 16)
                            .padding(.bottom, 2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius).stroke(.primary.opacity(0.1), lineWidth: 1)
            }
            
            // Actions
            VStack(spacing: 8) {
                #if os(macOS)
                HStack(spacing: 8) {
                    SettingsLink {
                        Text("Preferences")
                            .padding(.vertical, verticalPadding)
                            .frame(maxWidth: .infinity)
                            .background(.primary.opacity(0.1))
                            .clipShape(.rect(cornerRadius: cornerRadius))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: handleSubmit) {
                        Text("Submit")
                            .padding(.vertical, verticalPadding)
                            .frame(maxWidth: .infinity)
                            .background(.tint)
                            .overlay(.linearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom).blendMode(.softLight))
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
                #else
                VStack(spacing: 8) {
                    Button(action: handleSubmit) {
                        Text("Submit")
                            .padding(.vertical, verticalPadding)
                            .frame(maxWidth: .infinity)
                            .background(.tint)
                            .overlay(.linearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom).blendMode(.softLight))
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
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
    
    func handleSubmit() {
        guard !apiKey.isEmpty else { return }
        guard var service = store.get(serviceID: .openAI) else { return }
        
        // Update service with token and preferred models
        service.applyPreferredModels(Constants.openAIDefaults)
        service.credentials = .token(apiKey)
        store.upsert(service: service)
        
        // Update preferences with preferred services
        store.preferences.preferredChatServiceID = .openAI
        store.preferences.preferredImageServiceID = .openAI
        store.preferences.preferredEmbeddingServiceID = .openAI
        store.preferences.preferredTranscriptionServiceID = .openAI
        store.preferences.preferredToolServiceID = .openAI
        store.preferences.preferredVisionServiceID = .openAI
        store.preferences.preferredSpeechServiceID = .openAI
        store.preferences.preferredSummarizationServiceID = .openAI
        
        // Persist changes
        Task { try await store.saveAll() }
        
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
    ConversationBarrier()
        .environment(Store.preview)
        #if os(macOS)
        .frame(width: 310, height: 325)
        #endif
        .background(.white)
}
