// A conversation is an interaction between the user and a large language model (LLM). It has a title that helps
// set context for what the conversation is generally about and it has a history or messages.

import Foundation
import GenKit
import SharedKit

public struct Conversation: Codable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var picture: Asset?
    public var messages: [Message]
    public var suggestions: [String]
    public var tools: Set<Tool>
    public var state: State
    public var created: Date
    public var modified: Date
    
    public enum State: Codable {
        case processing
        case streaming
        case suggesting
        case none
    }
    
    public init(id: String = .id, title: String = Self.titlePlaceholder, subtitle: String? = nil, picture: Asset? = nil,
                messages: [Message] = [], suggestions: [String] = [], tools: Set<Tool> = [], state: State = .none) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.picture = picture
        self.messages = messages
        self.suggestions = suggestions
        self.tools = tools
        self.state = state
        self.created = .now
        self.modified = .now
    }
    
    mutating func apply(conversation: Conversation) {
        self.title = conversation.title
        self.subtitle = conversation.subtitle
        self.picture = conversation.picture
        self.messages = conversation.messages
        self.suggestions = conversation.suggestions
        self.tools = conversation.tools
        self.state = conversation.state
        self.modified = .now
    }
    
    public static var empty: Self { .init() }
    public static var titlePlaceholder = "New Conversation"
}

extension Conversation: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(modified)
    }
}

extension Conversation {
    
    public static var preview1: Conversation = {
        .init(
            messages: Agent.preview.instructions + [
                .init(role: .assistant, content: "What can I help you with today?"),
                .init(role: .user, content: "Explain thermodynamics like I'm five"),
                .init(role: .assistant, content: """
                    Thermodynamics is like a set of rules that explain how heat, energy, and things that move around \
                    work. It helps us understand why things can get hot or cold, and why some things can move while \
                    others stay still.

                    Think of all the things around you, like a toy car or a glass of water. Thermodynamics helps us \
                    understand how these things behave when they interact with heat or energy.
                    """),
                .init(role: .user, content: "Explain the zeroth law"),
                .init(role: .assistant, content: """
                    Sure, the Zeroth Law of Thermodynamics talks about temperature. It says if two objects, say A and B, \
                    are each in thermal equilibrium with a third object, C, then A and B are in thermal equilibrium with \
                    each other.
                    """),
            ],
            suggestions: [
                "What is the first law of thermodynamics?",
                "Explain thermal equilibrium.",
                "How does the zeroth law apply in real life?",
            ]
        )
    }()
    
    public static var preview2: Conversation = {
        .init(
            messages: Agent.preview.instructions + [
                .init(role: .user, content: "What are the latest Apple rumors?"),
                .init(
                    role: .assistant,
                    toolCalls: [
                        .init(
                            function: .init(
                                name: Tool.searchWeb.function.name,
                                arguments: """
                                    {"query": "latest apple rumors"}
                                    """
                            )
                        ),
                    ],
                    runID: "preview-run"
                ),
                .init(
                    role: .tool,
                    runID: "preview-run",
                    name: Tool.searchWeb.function.name,
                    metadata: ["label": "Searched the web for 'latest apple rumors'"]
                ),
                .init(
                    role: .assistant,
                    toolCalls: [
                        .init(
                            function: .init(
                                name: Tool.generateWebBrowse.function.name,
                                arguments: """
                                    {"instructions": "Summarize the key rumors about apple products in 2024", "url": "https://macrumors.com"}
                                    """
                            )
                        ),
                        .init(
                            function: .init(
                                name: Tool.generateWebBrowse.function.name,
                                arguments: """
                                    {"instructions": "Summarize the key rumors about apple products in 2024", "url": "https://9to5mac.com"}
                                    """
                            )
                        ),
                        .init(
                            function: .init(
                                name: Tool.generateWebBrowse.function.name,
                                arguments: """
                                    {"instructions": "Summarize the key rumors about apple products in 2024", "url": "https://cnet.com"}
                                    """
                            )
                        ),
                    ],
                    runID: "preview-run"
                ),
                .init(
                    role: .tool,
                    content: """
                        {"url": "macrumors.com", "summary": "iPad Models: Updates are expected for the iPad Air and iPad Pro models around late March/Early April, with potential changes across all iPad models later in the year."}
                        """,
                    runID: "preview-run",
                    name: Tool.generateWebBrowse.function.name,
                    metadata: ["label": "Read macrumors.com"]
                ),
                .init(
                    role: .tool,
                    content: """
                        {"url": "9to5mac.com", "summary": "iPhone 16 and iPhone 16 Pro: These are anticipated for a September launch, with rumors of a new design and updated features."},
                        """,
                    runID: "preview-run",
                    name: Tool.generateWebBrowse.function.name,
                    metadata: ["label": "Read 9to5mac.com"]
                ),
                .init(
                    role: .tool,
                    content: """
                        {"url": "cnet.com", "summary": "AirPods: Updates might come to the AirPods lineup, including a new version of AirPods Max and a potential new set of AirPods with Active Noise Cancellation."}
                        """,
                    runID: "preview-run",
                    name: Tool.generateWebBrowse.function.name,
                    metadata: ["label": "Read cnet.com"]
                ),
                .init(
                    role: .assistant,
                    content: """
                        In 2024, Apple has some exciting products and updates planned:
                        
                        1. iPad Models: Updates are expected for the iPad Air and iPad Pro models around late March/Early April, with potential changes across all iPad models later in the year.
                        2. iPhone 16 and iPhone 16 Pro: These are anticipated for a September launch, with rumors of a new design and updated features.
                        3. AirPods: Updates might come to the AirPods lineup, including a new version of AirPods Max and a potential new set of AirPods with Active Noise Cancellation.
                        """,
                    runID: "preview-run"
                ),
            ],
            suggestions: [
                "Tell me more about the Vision Pro headset.",
                "What's new with the iPhone 16?",
                "Can you explain the expected updates for iPads?",
            ])
    }()
}
