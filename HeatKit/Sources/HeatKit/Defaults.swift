import Foundation
import GenKit
import SharedKit

public struct Defaults {

    // MARK: - Agents

    public static let agents = [
        agentAssistant,
        agentAssistantWithTools,
        agentAssistantThoughtful,
        agentReasoner,
        agentAssistantCreator,
        agentInvestigator,
        agentReporter,
        agentCreativeWriter,
    ]

    public static let assistantDefaultID = agentAssistantThoughtful.id

    public static let agentAssistant = Agent(
        id: .init("bundle-assistant"),
        kind: .assistant,
        name: "Basic Assistant",
        instructions: AssistantInstructions
    )

    public static let agentAssistantWithTools = Agent(
        id: .init("bundle-assistant-with-tools"),
        kind: .assistant,
        name: "Basic Assistant (with tools)",
        instructions: AssistantInstructions,
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
            Toolbox.searchCalendar.name,
        ]
    )

    public static let agentReasoner = Agent(
        id: .init("bundle-assistant-reasoner"),
        kind: .assistant,
        name: "Basic Assistant (CoT)",
        instructions: AdvancedReasoningInstructions
    )

    public static let agentAssistantThoughtful = Agent(
        id: .init("bundle-assistant-thoughtful"),
        kind: .assistant,
        name: "Basic Assistant (Thoughtful)",
        instructions: AssistantThoughtfulInstructions,
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
            Toolbox.searchCalendar.name,
        ]
    )

    public static let agentAssistantCreator = Agent(
        id: .init("bundle-assistant-creator"),
        kind: .assistant,
        name: "Creator Assistant",
        instructions: AssistantCreatorInstructions,
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
            Toolbox.searchCalendar.name,
        ]
    )

    public static let agentInvestigator = Agent(
        id: .init("bundle-investigator"),
        kind: .prompt,
        name: "Investigate",
        instructions: InvestigatorInstructions,
        context: ["TOPIC": "", "NOTEBOOK": ""],
        tags: ["notebook"],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )

    public static let agentReporter = Agent(
        id: .init("bundle-reporter"),
        kind: .prompt,
        name: "Report",
        instructions: ReporterInstructions,
        context: ["TOPIC": "", "NOTEBOOK": ""],
        tags: ["outline", "report"],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )

    public static let agentCreativeWriter = Agent(
        id: .init("bundle-creative-writer"),
        kind: .prompt,
        name: "Creative Writer",
        instructions: CreativeWriterInstructions,
        context: ["REPORT": "", "WRITER": ""],
        tags: ["report", "summary", "headline"],
        toolIDs: [
            Toolbox.generateImages.name,
            Toolbox.browseWeb.name,
            Toolbox.searchWeb.name,
        ]
    )

    // MARK: - Services

    public static let services: [Service] = [
        anthropic,
        deepseek,
        elevenlabs,
        fal,
        grok,
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

    public static let deepseek =
        Service(
            id: .deepseek,
            name: "DeepSeek",
            host: "https://api.deepseek.com/v1"
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

    public static let grok =
        Service(
            id: .grok,
            name: "Grok",
            host: "https://api.x.ai/v1"
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
