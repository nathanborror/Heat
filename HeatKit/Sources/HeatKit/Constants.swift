import Foundation
import GenKit

public struct Constants {
    
    public static var defaultAgentID = "bundle-assistant"
    public static var defaultAgents: [Agent] = [.preview]
    
    public static var defaultChatServiceID = ""
    public static var defaultImageServiceID = ""
    public static var defaultEmbeddingServiceID = ""
    public static var defaultTranscriptionServiceID = ""
    public static var defaultToolServiceID = ""
    public static var defaultVisionServiceID = ""
    public static var defaultSpeechServiceID = ""
    
    public static var defaultServices: [Service] = [
        .init(
            id: "openai",
            name: "OpenAI",
            token: "",
            requiresToken: true
        ),
        .init(
            id: "mistral",
            name: "Mistral",
            token: "",
            requiresToken: true
        ),
        .init(
            id: "perplexity",
            name: "Perplexity",
            token: "",
            requiresToken: true
        ),
        .init(
            id: "ollama",
            name: "Ollama",
            host: URL(string: "http://localhost:11434/api")!,
            requiresHost: true
        ),
        .init(
            id: "elevenlabs",
            name: "ElevenLabs",
            token: "",
            requiresToken: true
        ),
    ]
}
