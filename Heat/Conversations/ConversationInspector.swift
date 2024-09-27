import SwiftUI
import HeatKit

struct ConversationInspector: View {
    let conversationID: String
    
    @State var instructions: String
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Instructions")
                    .font(.headline)
                Text(instructions)
                    .font(.footnote)
            }
            .padding()
        }
        .navigationTitle("Conversation")
        .onChange(of: isFocused) { oldValue, newValue in
            guard !newValue else { return }
            handleSave()
        }
    }
    
    func handleSave() {
        Task {
            try await ConversationsProvider.shared.upsert(instructions: instructions, conversationID: conversationID)
        }
    }
}
