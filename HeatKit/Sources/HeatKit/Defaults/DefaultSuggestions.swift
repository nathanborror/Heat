import Foundation

extension Defaults {

    public static let suggestionsInstruction = Instruction(
        kind: .task,
        instructions: """
            You are tasked with generating a list of brief suggested replies based on a chat session between a user and an AI assistant. These suggestions should anticipate what the user might say next in the conversation. Here is the chat history:

            <chat_history>
            {{history}}
            </chat_history>

            Your task is to create a list of suggested replies that the user might send next. Follow these guidelines when creating your suggestions:

            1. Keep the suggestions brief and to the point.
            2. Ensure the suggestions are relevant to the current topic of conversation.
            3. Vary the types of responses (e.g., questions, statements, requests for clarification).
            4. Make the suggestions sound natural and conversational.
            5. Avoid repeating information already provided in the chat history.
            6. Do not include any inappropriate or offensive content.

            Focus primarily on the most recent messages in the chat history, as these are most relevant to predicting the user's next response.

            Provide exactly 3 suggested replies. Format your output as a list, with each suggestion on a new line. Enclose your entire list of suggestions within <suggested_replies> tags.

            For example:

            <suggested_replies>
            Could you explain that in more detail?
            That's interesting. How does it compare to [related topic]?
            I'd like to learn more about [specific aspect mentioned].
            </suggested_replies>

            Remember, your goal is to anticipate plausible and helpful next messages from the user based on the context of the conversation.
            """
    )
}
