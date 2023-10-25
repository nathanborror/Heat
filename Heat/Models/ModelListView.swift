import SwiftUI
import HeatKit

struct ModelListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) var dismiss
    
    @Binding var modelID: String?
    
    @State var inspectingModel: Model? = nil
    
    var body: some View {
        Form {
            ForEach(store.models) { model in
                HStack {
                    Button(action: { handleSelection(model) }) {
                        HStack {
                            Text(model.name)
                                .lineLimit(1)
                            Spacer()
                            Text(model.size.toSizeString).font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                    
                    Button(action: { handleDetail(model) }) {
                        Image(systemName: "info.circle")
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .navigationTitle("Models")
        .sheet(item: $inspectingModel) { model in
            NavigationStack {
                ModelView(modelID: model.id)
            }.environment(store)
        }
    }
    
    func handleSelection(_ model: Model) {
        self.modelID = model.id
        dismiss()
        
        // Fetch all the model details
        Task { try await store.modelShow(modelID: model.id) }
    }
    
    func handleDetail(_ model: Model) {
        inspectingModel = model
    }
}
