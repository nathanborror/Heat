import Foundation
import GenKit

public struct Defaults {
    
    // MARK: - Templates
    
    public static let templates = [
        assistant,
        assistantThoughtful,
        assistantCreator,
    ]
    
    public static let assistantDefaultID = assistant.id
    
    public static let assistant = Template(
        id: "bundle-assistant",
        kind: .assistant,
        name: "Basic Assistant",
        instructions: AssistantInstructions
    )
    
    public static let assistantThoughtful = Template(
        id: "bundle-assistant-thoughtful",
        kind: .assistant,
        name: "Thoughtful Assistant",
        instructions: AssistantThoughtfulInstructions,
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let assistantCreator = Template(
        id: "bundle-assistant-creator",
        kind: .assistant,
        name: "Creator Assistant",
        instructions: AssistantCreatorInstructions,
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
            host: "http://127.0.0.1:11434/v1"
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
