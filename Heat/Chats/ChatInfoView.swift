import SwiftUI
import HeatKit

struct ChatInfoView: View {
    @Environment(Store.self) private var store
    
    let chatID: String
    @State var router: MainRouter

    var body: some View {
        RoutingView(router: router) {
            List {
                Text(model?.name ?? "Unknown Model")
            }
            .navigationTitle("Chat Info")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        router.dismiss()
                    }
                }
            }
        }
    }
    
    var agent: Agent? {
        guard let chat = store.get(chatID: chatID) else { return nil }
        return store.get(agentID: chat.agentID)
    }
    
    var chat: AgentChat? {
        store.get(chatID: chatID)
    }
    
    var model: Model? {
        guard let modelID = chat?.modelID else { return nil }
        return store.get(modelID: modelID)
    }
}
