import Foundation
import GenKit

public struct Defaults {
    
    // MARK: - Agents
    
    public static let agents = [
        agentAssistant,
        agentAssistantThoughtful,
        agentAssistantCreator,
        agentInvestigator,
        agentReporter,
        agentCreativeWriter,
    ]
    
    public static let assistantDefaultID = agentAssistant.id
    
    public static let agentAssistant = Agent(
        id: "bundle-assistant",
        kind: .assistant,
        name: "Basic Assistant",
        instructions: AssistantInstructions,
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let agentAssistantThoughtful = Agent(
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
    
    public static let agentAssistantCreator = Agent(
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
    
    public static let agentInvestigator = Agent(
        id: "bundle-investigator",
        kind: .prompt,
        name: "Investigate",
        instructions: InvestigatorInstructions,
        context: ["TOPIC": "", "EXISTING_NOTEBOOK": ""],
        tags: ["updated_notebook", "reasoning", "update_summary"],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let agentReporter = Agent(
        id: "bundle-reporter",
        kind: .prompt,
        name: "Report",
        instructions: ReporterInstructions,
        context: ["TOPIC": "", "NOTEBOOK": ""],
        tags: ["scratchpad", "report"],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )
    
    public static let agentCreativeWriter = Agent(
        id: "bundle-creative-writer",
        kind: .prompt,
        name: "Creative Writer",
        instructions: CreativeWriterInstructions,
        context: ["REPORT": "", "WRITER": ""],
        tags: ["rewritten_report", "style_explanation"],
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
