import SwiftUI
import GenKit
import HeatKit

struct ModelList: View {
    @Environment(Store.self) private var store
    
    var body: some View {
        List {
            ForEach(store.models) { model in
                NavigationLink {
                    ModelView(model: model)
                } label: {
                    Text(model.id)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ModelList()
    }.environment(Store.preview)
}
