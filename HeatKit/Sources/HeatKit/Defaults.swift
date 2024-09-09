import Foundation
import GenKit

public struct Defaults {
    
    public static let assistant = Agent(
        id: "bundle-assistant",
        name: "Assistant",
        instructions: AssistantInstructions(name: "Heat", creator: "Nathan Borror").render(),
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let assistantMaker = Agent(
        id: "bundle-assistant-maker",
        name: "Assistant Maker",
        instructions: AssistantArtifactsInstructions(name: "Heat", creator: "Nathan Borror").render(),
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
    
    public static let agents = [Defaults.assistant, Defaults.assistantMaker]
    public static let agentDefaultID = Defaults.assistantMaker.id
    
    public static let services: [Service] = [
        .init(
            id: .openAI,
            name: "OpenAI"
        ),
        .init(
            id: .mistral,
            name: "Mistral"
        ),
        .init(
            id: .perplexity,
            name: "Perplexity"
        ),
        .init(
            id: .ollama,
            name: "Ollama"
        ),
        .init(
            id: .elevenLabs,
            name: "ElevenLabs"
        ),
        .init(
            id: .anthropic,
            name: "Anthropic"
        ),
        .init(
            id: .google,
            name: "Google"
        ),
        .init(
            id: .fal,
            name: "Fal"
        ),
        .init(
            id: .groq,
            name: "Groq",
            host: "https://api.groq.com/openai/v1"
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
