import SwiftUI
import HeatKit

struct ModelList: View {
    @Environment(Store.self) private var store
    
    var body: some View {
        List {
            ForEach(store.models) { model in
                NavigationLink {
                    ModelView(modelID: model.id)
                } label: {
                    Text(model.name)
                }
            }
        }
        .refreshable(action: handleLoadModels)
    }
    
    func handleLoadModels() {
        
    }
}

#Preview {
    NavigationStack {
        ModelList()
    }.environment(Store.preview)
}
