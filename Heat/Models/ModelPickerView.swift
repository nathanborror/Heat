import SwiftUI
import HeatKit

struct ModelPickerView: View {
    @Environment(Store.self) private var store
    
    @State var agent: Agent
    @State var router: MainRouter
    
    var body: some View {
        RoutingView(router: router) {
            Form {
                ForEach(store.models) { model in
                    HStack {
                        Button(action: { handleSelection(model.id) }) {
                            HStack {
                                Text(model.name)
                                    .lineLimit(1)
                                Spacer()
                                Text(model.size.toSizeString).font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                        
                        Button(action: { router.presentingModel(model.id) }) {
                            Image(systemName: "info.circle")
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Pick Model")
        }
    }
    
    func handleSelection(_ modelID: String) {
        let chat = store.createChat(modelID: modelID, agentID: agent.id)
        Task { await store.upsert(chat: chat) }
        router.presentNewChat(chat.id)
    }
}
