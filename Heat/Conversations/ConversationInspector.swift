import SwiftUI
import HeatKit

struct ConversationInspector: View {
    let conversationID: String
    
    @State var instructions: String
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Instructions", text: $instructions, axis: .vertical)
                    .focused($isFocused)
            } header: {
                Text("Instructions")
            }
        }
        .formStyle(.grouped)
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
