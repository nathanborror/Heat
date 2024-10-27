import SwiftUI
import HeatKit

struct ConversationViewInspector: View {
    @Environment(ConversationsProvider.self) var conversationsProvider

    let conversationID: String

    private var conversation: Conversation? {
        try? conversationsProvider.get(conversationID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Instructions")
                    .font(.headline)
                Text(conversation?.instructions ?? "")
                    .font(.footnote)
            }
            .padding()
        }
        .navigationTitle("Conversation")
    }
}
