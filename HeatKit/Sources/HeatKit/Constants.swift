import Foundation
import GenKit

public struct Constants {
    
    public static var defaultAgentID = "bundle-assistant"
    public static var defaultAgents: [Agent] = [.preview]
    
    public static var defaultChatServiceID: Service.ServiceID? = nil
    public static var defaultImageServiceID: Service.ServiceID? = nil
    public static var defaultEmbeddingServiceID: Service.ServiceID? = nil
    public static var defaultTranscriptionServiceID: Service.ServiceID? = nil
    public static var defaultToolServiceID: Service.ServiceID? = nil
    public static var defaultVisionServiceID: Service.ServiceID? = nil
    public static var defaultSpeechServiceID: Service.ServiceID? = nil
    
    public static var defaultServices: [Service] = [
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
    ]
    
    public static var openAIDefaults =
        Service(
            id: .openAI,
            name: "OpenAI",
            preferredChatModel: "gpt-4",
            preferredImageModel: "dall-e-3",
            preferredEmbeddingModel: "text-embeddings-3-small",
            preferredTranscriptionModel: "whisper-1",
            preferredToolModel: "gpt-4",
            preferredVisionModel: "gpt-4-vision-preview",
            preferredSpeechModel: "tts-1-hd"
        )
    
    public static var anthropicDefaults =
        Service(
            id: .anthropic,
            name: "Anthropic",
            preferredChatModel: "claude-3-opus-20240229"
        )
    
    public static var mistralDefaults =
        Service(
            id: .mistral,
            name: "Mistral",
            preferredChatModel: "mistral-large-latest",
            preferredEmbeddingModel: "mistral-embed",
            preferredToolModel: "mistral-large-latest"
        )
    
    public static var perplexityDefaults =
        Service(
            id: .perplexity,
            name: "Perplexity",
            preferredChatModel: "pplx-70b-chat"
        )
    
    public static var googleDefaults =
        Service(
            id: .google,
            name: "Google",
            preferredChatModel: "gemini-pro"
        )
}
