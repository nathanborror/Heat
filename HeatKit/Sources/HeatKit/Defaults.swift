import Foundation
import GenKit
import SharedKit

public struct Defaults {

    public static let services: [Service] = [
        anthropic,
        deepseek,
        elevenlabs,
        fal,
        grok,
        groq,
        llama,
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

    public static let llama =
        Service(
            id: .llama,
            name: "Llama"
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
