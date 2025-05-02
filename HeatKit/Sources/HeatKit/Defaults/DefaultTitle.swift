import Foundation

extension Defaults {

    public static let titleInstruction = Instruction(
        kind: .task,
        instructions: """
            Based on the conversation transcript, your task is to determine if there is a clear topic of conversation and, if so, return a concise title for it. Here is the chat history:

            <chat_history>
            {{history}}
            </chat_history>

            To determine if there is a clear topic:
            1. Read through the entire conversation.
            2. Look for recurring themes or subjects that dominate the discussion.
            3. Ignore greetings, small talk, or unrelated tangents.

            If you identify a clear topic:
            1. Create a title that captures the main subject of the conversation.
            2. Keep the title under 4 words.
            3. Make sure the title is descriptive and relevant to the main discussion.

            Do not return a title if:
            1. There is no clear topic of conversation.
            2. The conversation consists only of greetings or small talk.
            3. The discussion is too varied or unfocused to summarize in a short title.

            If you determine a title is appropriate, output it within <title> tags. If no title should be returned, \
            output an empty <title> tag.
            """
    )
}
