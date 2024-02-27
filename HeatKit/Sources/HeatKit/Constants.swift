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
}
