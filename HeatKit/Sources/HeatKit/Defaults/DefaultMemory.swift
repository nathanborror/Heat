import Foundation

extension Defaults {

    public static let memoryInstruction = Instruction(
        kind: .task,
        instructions: """
            Return a list of new things to remember about the given user based on the given content. Use the existing memories to determine if there is anything new to remember. Some examples include names, important dates, facts about the user, and interests. Basically anything meaninful that would help relate to the user more.

            <user_content>
            {{content}}
            </user_content>

            <existing_memories>
            {{memories}}
            </existing_memories>

            Provide new memories in a list. It's acceptable to return zero memories if there is nothing to remember. Format your output as a list, with each memory on a new line. Enclose your entire list of memories within <memories> tags.

            For example:

            <memories>
            User's name is Nathan
            Nathan lives in California
            </memories>
            """
    )
}
