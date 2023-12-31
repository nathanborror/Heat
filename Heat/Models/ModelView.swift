import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ModelView", category: "Heat")

struct ModelView: View {
    @Environment(Store.self) private var store
    
    let model: Model
    
    var body: some View {
        List {
            Text(model.id)
        }
        .navigationTitle("Model")
    }
}
