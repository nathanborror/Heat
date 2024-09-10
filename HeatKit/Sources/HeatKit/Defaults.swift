import Foundation
import GenKit

public struct Defaults {
    
    // MARK: - Agents
    
    public static let agents = [
        assistant,
        assistantMaker
    ]
    
    public static let agentDefaultID = assistantMaker.id
    
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
    
    // MARK: - Services
    
    public static let services: [Service] = [
        anthropic,
        elevenlabs,
        fal,
        google,
        groq,
        mistral,
        ollama,
        openAI,
        perplexity,
    ]
    
    public static let anthropic =
        Service(
            id: .anthropic,
            name: "Anthropic",
            models: [
                anthropic_claude_3_5_sonnet,
                anthropic_claude_3_haiku,
            ],
            preferredChatModel: anthropic_claude_3_5_sonnet.id,
            preferredToolModel: anthropic_claude_3_5_sonnet.id,
            preferredVisionModel: anthropic_claude_3_5_sonnet.id,
            preferredSummarizationModel: anthropic_claude_3_haiku.id
        )
    
    public static var elevenlabs =
        Service(
            id: .elevenLabs,
            name: "ElevenLabs",
            models: [elevenlabs_monolingual_1],
            preferredSpeechModel: elevenlabs_monolingual_1.id
        )
    
    public static var fal =
        Service(
            id: .fal,
            name: "Fal",
            models: [fal_sdxl_fast],
            preferredImageModel: fal_sdxl_fast.id
        )
    
    public static let google =
        Service(
            id: .google,
            name: "Google",
            models: [google_gemini_pro],
            preferredChatModel: google_gemini_pro.id
        )
    
    public static var groq =
        Service(
            id: .groq,
            name: "Groq",
            host: "https://api.groq.com/openai/v1",
            models: [
                groq_llama_3_1_70b_versatile,
                groq_llama_3_1_8b_instant,
            ],
            preferredChatModel: groq_llama_3_1_70b_versatile.id,
            preferredToolModel: groq_llama_3_1_70b_versatile.id,
            preferredSummarizationModel: groq_llama_3_1_8b_instant.id
        )
    
    public static let mistral =
        Service(
            id: .mistral,
            name: "Mistral",
            models: [
                mistral_large,
                mistral_small,
                mistral_embed,
            ],
            preferredChatModel: mistral_large.id,
            preferredEmbeddingModel: mistral_embed.id,
            preferredToolModel: mistral_large.id,
            preferredSummarizationModel: mistral_small.id
        )
    
    public static var ollama =
        Service(
            id: .ollama,
            name: "Ollama",
            host: "http://127.0.0.1:11434/api"
        )
    
    public static let openAI =
        Service(
            id: .openAI,
            name: "OpenAI",
            models: [
                openAI_gpt_4o,
                openAI_gpt_4o_mini,
                openAI_dalle_3,
                openAI_embedding_ada_2,
                openAI_whisper_1,
                openAI_tts_1_hd,
            ],
            preferredChatModel: openAI_gpt_4o.id,
            preferredImageModel: openAI_dalle_3.id,
            preferredEmbeddingModel: openAI_embedding_ada_2.id,
            preferredTranscriptionModel: openAI_whisper_1.id,
            preferredToolModel: openAI_gpt_4o.id,
            preferredVisionModel: openAI_gpt_4o.id,
            preferredSpeechModel: openAI_tts_1_hd.id,
            preferredSummarizationModel: openAI_gpt_4o_mini.id
        )
    
    public static let perplexity =
        Service(
            id: .perplexity,
            name: "Perplexity",
            models: [
                perplexity_llama_3_1_large,
                perplexity_llama_3_1_small,
            ],
            preferredChatModel: perplexity_llama_3_1_large.id,
            preferredSummarizationModel: perplexity_llama_3_1_small.id
        )
    
    // MARK: - Models
    
    public static var anthropic_claude_3_5_sonnet = Model(id: "claude-3-5-sonnet-20240620", owner: "anthropic", contextWindow: 200_000, maxOutput: 8192)
    public static var anthropic_claude_3_haiku = Model(id: "claude-3-haiku-20240307", owner: "anthropic", contextWindow: 200_000, maxOutput: 4096)
    
    public static var elevenlabs_monolingual_1 = Model(id: "eleven_monolingual_v1", owner: "elevenlabs")
    
    public static var fal_sdxl_fast = Model(id: "fast-sdxl", owner: "fal")
    
    public static var google_gemini_pro = Model(id: "gemini-pro", owner: "google")
    
    public static var groq_llama_3_1_70b_versatile = Model(id: "llama-3.1-70b-versatile", owner: "groq")
    public static var groq_llama_3_1_8b_instant = Model(id: "llama-3.1-8b-instant", owner: "groq")
    
    public static var mistral_large = Model(id: "mistral-large-latest", owner: "mistral")
    public static var mistral_small = Model(id: "mistral-small-latest", owner: "mistral")
    public static var mistral_embed = Model(id: "mistral-embed", owner: "mistral")
    
    public static var openAI_gpt_4o = Model(id: "gpt-4o", owner: "openai")
    public static var openAI_gpt_4o_mini = Model(id: "gpt-4o-mini", owner: "openai")
    public static var openAI_dalle_3 = Model(id: "dall-e-3", owner: "openai")
    public static var openAI_embedding_ada_2 = Model(id: "text-embedding-ada-002", owner: "openai")
    public static var openAI_whisper_1 = Model(id: "whisper-1", owner: "openai")
    public static var openAI_tts_1_hd = Model(id: "tts-1-hd", owner: "openai")
    
    public static var perplexity_llama_3_1_large = Model(id: "llama-3.1-sonar-large-128k-chat", owner: "perplexity")
    public static var perplexity_llama_3_1_small = Model(id: "llama-3.1-sonar-small-128k-chat", owner: "perplexity")
}
