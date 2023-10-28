import Foundation

extension Agent {
    
    public static var assistant: Self {
        .init(
            id: "bundle-assistant",
            name: "Assistant",
            picture: .none,
            prompt: "You are a helpful assistant."
        )
    }
    
    public static var vent: Self {
        .init(
            id: "bundle-vent",
            name: "Just vent",
            picture: .bundle("Covers/Sunrise"),
            prompt: "I just want to vent."
        )
    }
    
    public static var learn: Self {
        .init(
            id: "bundle-learn",
            name: "Learn about something new",
            picture: .bundle("Covers/Tent"),
            prompt: "I want to learn about something new."
        )
    }
    
    public static var brainstorm: Self {
        .init(
            id: "bundle-brainstorm",
            name: "Brainstorm ideas",
            picture: .bundle("Covers/Dunes"),
            prompt: "I want to brainstorm ideas."
        )
    }
    
    public static var advice: Self {
        .init(
            id: "bundle-advice",
            name: "Need advice",
            picture: .bundle("Covers/SeaSunrise"),
            prompt: "I need advice about something."
        )
    }
    
    public static var anxious: Self {
        .init(
            id: "bundle-anxious",
            name: "Feeling anxious",
            picture: .bundle("Covers/Clouds"),
            prompt: "I've been feeling anxious."
        )
    }
    
    public static var philisophical: Self {
        .init(
            id: "bundle-philisophical",
            name: "Get philisophical",
            picture: .bundle("Covers/Cube"),
            prompt: "I want to get philisophical."
        )
    }
    
    public static var discover: Self {
        .init(
            id: "bundle-discover",
            name: "Discover books, music or podcasts",
            picture: .bundle("Covers/Bubbles"),
            prompt: "I want to discover new books, music or podcasts."
        )
    }
    
    public static var coach: Self {
        .init(
            id: "bundle-coach",
            name: "Coach me through a problem",
            picture: .bundle("Covers/Hallway"),
            prompt: "Coach me through a problem."
        )
    }
    
    public static var journal: Self {
        .init(
            id: "bundle-journal",
            name: "Journal it out",
            picture: .bundle("Covers/Spiral"),
            prompt: "You are a helpful assistant."
        )
    }
}

// Practice a big conversation
// Relationship advice
// I need a safe space for something
// Plan for the future
// Play a game
// Think of a gift to give
// Weight the pros and cons of a decision
// Get motivated
// Tackle homework
// Journal it out
// World building for games
// Teach me a fun fact
// Career plan
// Master a work task
// Help me write a text or message
// Feel calm
