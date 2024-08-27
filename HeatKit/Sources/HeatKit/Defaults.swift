import Foundation
import GenKit

public struct Defaults {
    
    public static let assistant = Agent(
        id: "bundle-assistant",
        name: "Assistant",
        instructions: assistantInstructions(name: "Heat", creator: "Nathan Borror"),
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let chatServiceID: Service.ServiceID? = nil
    public static let imageServiceID: Service.ServiceID? = nil
    public static let embeddingServiceID: Service.ServiceID? = nil
    public static let transcriptionServiceID: Service.ServiceID? = nil
    public static let toolServiceID: Service.ServiceID? = nil
    public static let visionServiceID: Service.ServiceID? = nil
    public static let speechServiceID: Service.ServiceID? = nil
    public static let summarizationServiceID: Service.ServiceID? = nil
    
    public static let services: [Service] = [
        .init(
            id: .openAI,
            name: "OpenAI",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .mistral,
            name: "Mistral",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .perplexity,
            name: "Perplexity",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .ollama,
            name: "Ollama",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .elevenLabs,
            name: "ElevenLabs",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .anthropic,
            name: "Anthropic",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .google,
            name: "Google",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .fal,
            name: "Fal",
            credentials: .hostAndToken(nil, nil)
        ),
        .init(
            id: .groq,
            name: "Groq",
            credentials: .hostAndToken(.init(string: "https://api.groq.com/openai/v1")!, nil)
        ),
    ]
    
    public static let openAI =
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
            preferredSummarizationModel: "gpt-4o-mini"
        )
    
    public static let anthropic =
        Service(
            id: .anthropic,
            name: "Anthropic",
            preferredChatModel: "claude-3-5-sonnet-20240620",
            preferredToolModel: "claude-3-5-sonnet-20240620",
            preferredVisionModel: "claude-3-5-sonnet-20240620",
            preferredSummarizationModel: "claude-3-haiku-20240307"
        )
    
    public static let mistral =
        Service(
            id: .mistral,
            name: "Mistral",
            preferredChatModel: "mistral-large-latest",
            preferredEmbeddingModel: "mistral-embed",
            preferredToolModel: "mistral-large-latest"
        )
    
    public static let perplexity =
        Service(
            id: .perplexity,
            name: "Perplexity",
            preferredChatModel: "pplx-70b-chat"
        )
    
    public static let google =
        Service(
            id: .google,
            name: "Google",
            preferredChatModel: "gemini-pro"
        )
}
