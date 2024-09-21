import Foundation
import GenKit

public struct Defaults {
    
    // MARK: - Agents
    
    public static let agents = [
        assistant,
        assistantMaker,
    ]
    
    public static let agentDefaultID = assistantMaker.id
    
    public static let assistant = Agent(
        id: "bundle-assistant",
        name: "Assistant",
        instructions: Prompt.render(AssistantInstructions, with: ["NAME": "Heat", "CREATOR": "Nathan Borror"]),
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let assistantMaker = Agent(
        id: "bundle-assistant-maker",
        name: "Assistant Maker",
        instructions: Prompt.render(AssistantArtifactsInstructions, with: ["NAME": "Heat", "CREATOR": "Nathan Borror"]),
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
            name: "Anthropic"
        )
    
    public static let elevenlabs =
        Service(
            id: .elevenLabs,
            name: "ElevenLabs"
        )
    
    public static let fal =
        Service(
            id: .fal,
            name: "Fal"
        )
    
    public static let google =
        Service(
            id: .google,
            name: "Google"
        )
    
    public static let groq =
        Service(
            id: .groq,
            name: "Groq",
            host: "https://api.groq.com/openai/v1"
        )
    
    public static let mistral =
        Service(
            id: .mistral,
            name: "Mistral"
        )
    
    public static let ollama =
        Service(
            id: .ollama,
            name: "Ollama",
            host: "http://127.0.0.1:11434/api"
        )
    
    public static let openAI =
        Service(
            id: .openAI,
            name: "OpenAI"
        )
    
    public static let perplexity =
        Service(
            id: .perplexity,
            name: "Perplexity"
        )
    
    // MARK: - Models
    
    public static let anthropic_claude_3_5_sonnet = Model(id: "claude-3-5-sonnet-20240620", owner: "anthropic", contextWindow: 200_000, maxOutput: 8192)
    public static let anthropic_claude_3_haiku = Model(id: "claude-3-haiku-20240307", owner: "anthropic", contextWindow: 200_000, maxOutput: 4096)
    
    public static let elevenlabs_monolingual_1 = Model(id: "eleven_monolingual_v1", owner: "elevenlabs")
    
    public static let fal_sdxl_fast = Model(id: "fast-sdxl", owner: "fal")
    
    public static let google_gemini_pro = Model(id: "gemini-pro", owner: "google")
    
    public static let groq_llama_3_1_70b_versatile = Model(id: "llama-3.1-70b-versatile", owner: "groq")
    public static let groq_llama_3_1_8b_instant = Model(id: "llama-3.1-8b-instant", owner: "groq")
    
    public static let mistral_large = Model(id: "mistral-large-latest", owner: "mistral")
    public static let mistral_small = Model(id: "mistral-small-latest", owner: "mistral")
    public static let mistral_embed = Model(id: "mistral-embed", owner: "mistral")
    
    public static let openAI_gpt_4o = Model(id: "gpt-4o", owner: "openai")
    public static let openAI_gpt_4o_mini = Model(id: "gpt-4o-mini", owner: "openai")
    public static let openAI_dalle_3 = Model(id: "dall-e-3", owner: "openai")
    public static let openAI_embedding_ada_2 = Model(id: "text-embedding-ada-002", owner: "openai")
    public static let openAI_whisper_1 = Model(id: "whisper-1", owner: "openai")
    public static let openAI_tts_1_hd = Model(id: "tts-1-hd", owner: "openai")
    
    public static let perplexity_llama_3_1_large = Model(id: "llama-3.1-sonar-large-128k-chat", owner: "perplexity")
    public static let perplexity_llama_3_1_small = Model(id: "llama-3.1-sonar-small-128k-chat", owner: "perplexity")
}
