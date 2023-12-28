import SwiftUI
import HeatKit

struct ModelView: View {
    @Environment(Store.self) private var store
    
    let modelID: String
    
    private let fontSize: CGFloat = 14
    
    var body: some View {
        List {
            if let model = store.get(modelID: modelID) {
                Section {
                    Text(model.size.toSizeString)
                }
                
                if let system = model.system {
                    Section {
                        Text(system)
                            .font(.system(size: fontSize, design: .monospaced))
                    } header: {
                        Text("System Prompt")
                    }
                }
                
                if let modelfile = model.modelfile {
                    Section {
                        Text(modelfile)
                            .font(.system(size: fontSize, design: .monospaced))
                    } header: {
                        Text("Model File")
                    }
                }
                
                if let template = model.template {
                    Section {
                        Text(template)
                            .font(.system(size: fontSize, design: .monospaced))
                    } header: {
                        Text("Template")
                    }
                }
                
                if let parameters = model.parameters {
                    Section {
                        Text(parameters)
                            .font(.system(size: fontSize, design: .monospaced))
                    } header: {
                        Text("Parameters")
                    }
                }
                
                if let license = model.license {
                    Section {
                        Text(license)
                            .font(.system(size: fontSize, design: .monospaced))
                    } header: {
                        Text("License")
                    }
                }
            }
        }
        .navigationTitle("Model")
        .onAppear {
            handleDetails(modelID: modelID)
        }
    }
    
    func handleDetails(modelID: String) {
        guard let host = Bundle.main.infoDictionary?["OllamaHost"] as? String else {
            return
        }
        guard let url = URL(string: host) else {
            return
        }
        Task {
            await ModelManager(url: url, models: store.models)
                .refresh()
                .details(for: modelID)
                .sink { store.upsert(models: $0) }
        }
    }
}
