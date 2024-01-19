import Foundation
import GenKit

public struct Constants {
    
    public static var defaultChatServiceID = openAI
    public static var defaultImageServiceID = openAI
    public static var defaultEmbeddingServiceID = openAI
    public static var defaultTranscriptionServiceID = openAI
    
    public static var defaultServices: [Service] {
        [
            .init(
                id: openAI,
                name: "OpenAI",
                requiresToken: true
            ),
            .init(
                id: "mistral",
                name: "Mistral",
                requiresToken: true
            ),
            .init(
                id: "perplexity",
                name: "Perplexity",
                requiresToken: true
            ),
            .init(
                id: "ollama",
                name: "Ollama",
                requiresHost: true
            ),
        ]
    }
    
    static var openAI = "openai"
}
