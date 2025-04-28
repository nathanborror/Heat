import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ServiceForm", category: "App")

struct ServiceForm: View {
    @Environment(AppState.self) var state
    @Environment(ServicesManager.self) var manager

    @State var service: Service

    var body: some View {
        Form {
            Section {
                TextField("Host", text: $service.host)
                    .autocorrectionDisabled()
                    .textContentType(.URL)

                TextField("Token", text: $service.token)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
            }

            #if os(macOS)
            Divider()
                .padding(.vertical)
            #endif

            Section {
                ServiceModelPicker("Chats", service.models, selection: $service.preferredChatModel)
                ServiceModelPicker("Images", service.models, selection: $service.preferredImageModel)
                ServiceModelPicker("Embeddings", service.models, selection: $service.preferredEmbeddingModel)
                ServiceModelPicker("Transcriptions", service.models, selection: $service.preferredTranscriptionModel)
                ServiceModelPicker("Speech", service.models, selection: $service.preferredSpeechModel)
                ServiceModelPicker("Summarization", service.models, selection: $service.preferredSummarizationModel)
            }

            Section {
                Button("Load Models") {
                    handleLoadModels()
                }
                .disabled(service.token.isEmpty && service.host.isEmpty)
            }
        }
        .navigationTitle(service.name)
        .onAppear {
            handleLoadModels()
        }
        .onDisappear {
            handleSave()
        }
    }

    func handleLoadModels() {
        Task {
            do {
                let client = service.modelService()
                service.models = try await client.models()
                manager.update(service: service)
            } catch {
                state.log(error: error)
            }
        }
    }

    func handleSave() {
        manager.update(service: service)
    }
}

struct ServiceModelPicker: View {
    let title: String
    let models: [Model]

    @Binding var selection: String?

    init(_ title: String, _ models: [Model]?, selection: Binding<String?>) {
        self.title = title
        self.models = models ?? []
        self._selection = selection
    }

    var body: some View {
        Picker(selection: $selection) {
            Text("None").tag(String?.none)
            Divider()
            ForEach(models.sorted(by: { $0.id < $1.id })) { model in
                Text(model.name ?? model.id).tag(model.id)
            }
        } label: {
            Text(title)
        }
    }
}
