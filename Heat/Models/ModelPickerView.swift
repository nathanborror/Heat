import SwiftUI
import HeatKit

struct ModelPickerView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    
    var body: some View {
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
                    
                    Button(action: { print("not implemented") }) {
                        Image(systemName: "info.circle")
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .navigationTitle("Pick Model")
        .onAppear {
            Task {
                try await store.loadModels()
                try await store.loadModelDetails()
            }
        }
    }
    
    func handleSelection(_ modelID: String) {
        let chat = store.createChat(modelID: modelID, agentID: agent.id)
        Task { await store.upsert(chat: chat) }
        dismiss()
    }
}
