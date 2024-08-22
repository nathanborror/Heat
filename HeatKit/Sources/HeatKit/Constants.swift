import Foundation
import GenKit

public struct Constants {
    
    public static let defaultAgent = Agent(
        id: "bundle-assistant",
        name: "Assistant",
        instructions: [.init(role: .system, content: "You are a helpful assistant.")],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let defaultChatServiceID: Service.ServiceID? = nil
    public static let defaultImageServiceID: Service.ServiceID? = nil
    public static let defaultEmbeddingServiceID: Service.ServiceID? = nil
    public static let defaultTranscriptionServiceID: Service.ServiceID? = nil
    public static let defaultToolServiceID: Service.ServiceID? = nil
    public static let defaultVisionServiceID: Service.ServiceID? = nil
    public static let defaultSpeechServiceID: Service.ServiceID? = nil
    public static let defaultSummarizationServiceID: Service.ServiceID? = nil
    
    public static let defaultServices: [Service] = [
        .init(
            id: .openAI,
            name: "OpenAI",
            credentials: nil
        ),
        .init(
            id: .mistral,
            name: "Mistral",
            credentials: nil
        ),
        .init(
            id: .perplexity,
            name: "Perplexity",
            credentials: nil
        ),
        .init(
            id: .ollama,
            name: "Ollama",
            credentials: .host(URL(string: "http://localhost:11434/api")!)
        ),
        .init(
            id: .elevenLabs,
            name: "ElevenLabs",
            credentials: nil
        ),
        .init(
            id: .anthropic,
            name: "Anthropic",
            credentials: nil
        ),
        .init(
            id: .google,
            name: "Google",
            credentials: nil
        ),
        .init(
            id: .fal,
            name: "Fal",
            credentials: nil
        )
    ]
    
    public static let openAIDefaults =
        Service(
            id: .openAI,
            name: "OpenAI",
            preferredChatModel: "gpt-4o",
            preferredImageModel: "dall-e-3",
            preferredEmbeddingModel: "text-embedding-3-small",
            preferredTranscriptionModel: "whisper-1",
            preferredToolModel: "gpt-4o",
            preferredVisionModel: "gpt-4o",
            preferredSpeechModel: "tts-1-hd",
            preferredSummarizationModel: "gpt-4o"
        )
    
    public static let anthropicDefaults =
        Service(
            id: .anthropic,
            name: "Anthropic",
            preferredChatModel: "claude-3-5-sonnet-20240620",
            preferredToolModel: "claude-3-5-sonnet-20240620",
            preferredVisionModel: "claude-3-5-sonnet-20240620",
            preferredSummarizationModel: "claude-3-haiku-20240307"
        )
    
    public static let mistralDefaults =
        Service(
            id: .mistral,
            name: "Mistral",
            preferredChatModel: "mistral-large-latest",
            preferredEmbeddingModel: "mistral-embed",
            preferredToolModel: "mistral-large-latest"
        )
    
    public static let perplexityDefaults =
        Service(
            id: .perplexity,
            name: "Perplexity",
            preferredChatModel: "pplx-70b-chat"
        )
    
    public static let googleDefaults =
        Service(
            id: .google,
            name: "Google",
            preferredChatModel: "gemini-pro"
        )
}
