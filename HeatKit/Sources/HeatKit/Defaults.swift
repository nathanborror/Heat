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
}
