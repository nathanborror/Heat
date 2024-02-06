import Foundation
import GenKit

public struct Constants {
    
    public static var defaultAgentID = "bundle-assistant"
    public static var defaultAgents: [Agent] = [
        .init(
            id: defaultAgentID,
            name: "Assistant",
            instructions: [
                .init(kind: .instruction, role: .system, content: "You are a helpful assistant."),
                .init(kind: .instruction, role: .user, content: "Introduce yourself."),
            ]
        )
    ]
    
    public static var defaultChatServiceID = ollama
    public static var defaultImageServiceID = ollama
    public static var defaultEmbeddingServiceID = ollama
    public static var defaultTranscriptionServiceID = ollama
    public static var defaultVisionServiceID = ollama
    
    public static var defaultServices: [Service] = [
        .init(
            id: "openai",
            name: "OpenAI",
            token: "",
            preferredChatModel: "gpt-4",
            preferredImageModel: "dall-e-3",
            preferredEmbeddingModel: "text-embedding-ada-002",
            preferredTranscriptionModel: "whisper-1",
            preferredVisionModel: "gpt-4-vision-preview",
            requiresToken: true
        ),
        .init(
            id: "mistral",
            name: "Mistral",
            token: "",
            preferredChatModel: "mistral-medium",
            preferredEmbeddingModel: "mistral-embed",
            requiresToken: true
        ),
        .init(
            id: "perplexity",
            name: "Perplexity",
            token: "",
            preferredChatModel: "pplx-70b-chat",
            requiresToken: true
        ),
        .init(
            id: "ollama",
            name: "Ollama",
            host: URL(string: "http://localhost:8080/api")!,
            requiresHost: true
        ),
    ]
    
    static var ollama = "ollama"
}
