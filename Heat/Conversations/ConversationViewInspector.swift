import SwiftUI
import HeatKit

struct ConversationViewInspector: View {
    @Environment(AppState.self) var state

    let conversationID: String

    private var conversation: Conversation? {
        try? state.conversationsProvider.get(conversationID)
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
