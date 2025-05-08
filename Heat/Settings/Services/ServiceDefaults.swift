import SwiftUI
import GenKit
import HeatKit

struct ServiceDefaults: View {
    @Environment(AppState.self) var state
    @Environment(ServicesManager.self) var manager

    var body: some View {
        @Bindable var manager = manager
        Section("Defaults") {
            Picker("Chats", selection: $manager.serviceChatDefault) {
                servicePickerView(\.supportsChats)
            }
            Picker("Images", selection: $manager.serviceImageDefault) {
                servicePickerView(\.supportsImages)
            }
            Picker("Embeddings", selection: $manager.serviceEmbeddingDefault) {
                servicePickerView(\.supportsEmbeddings)
            }
            Picker("Transcriptions", selection: $manager.serviceTranscriptionDefault) {
                servicePickerView(\.supportsTranscriptions)
            }
            Picker("Speech", selection: $manager.serviceSpeechDefault) {
                servicePickerView(\.supportsSpeech)
            }
            Picker("Summarization", selection: $manager.serviceSummarizationDefault) {
                servicePickerView(\.supportsSummarization)
            }
        }
    }

    func servicePickerView(_ prop: KeyPath<Service, Bool>) -> some View {
        Group {
            Text("None").tag(String?.none)
            Divider()
            ForEach(manager.services.filter { $0[keyPath: prop] }) { service in
                Text(service.name).tag(service.id)
            }
        }
    }
}
