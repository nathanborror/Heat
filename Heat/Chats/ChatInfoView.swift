import SwiftUI
import HeatKit

struct ChatInfoView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let chatID: String?
    
    @Binding var modelID: String

    var body: some View {
        List {
            Section {
                ForEach(store.models) { model in
                    Button(action: { handleSelection(model) }) {
                        HStack {
                            Text(model.name)
                                .tint(.primary)
                            Spacer()
                            if model.id == modelID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } header: {
                Text("Models")
            }
        }
        .navigationTitle("Chat Info")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    var agent: Agent? {
        guard let chatID = chatID else { return nil }
        guard let chat = store.get(chatID: chatID) else { return nil }
        return store.get(agentID: chat.agentID)
    }
    
    var chat: AgentChat? {
        guard let chatID = chatID else { return nil }
        return store.get(chatID: chatID)
    }
    
    var model: Model? {
        guard let modelID = chat?.modelID else { return nil }
        return store.get(modelID: modelID)
    }
    
    func handleSelection(_ model: Model) {
        modelID = model.id
        dismiss()
    }
}

