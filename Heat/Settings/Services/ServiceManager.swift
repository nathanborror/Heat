import Foundation
import Observation
import GenKit
import HeatKit

@Observable
@MainActor
class ServicesManager {
    var services: [Service] = []

    var serviceChatDefault: String? = nil
    var serviceImageDefault: String? = nil
    var serviceEmbeddingDefault: String? = nil
    var serviceTranscriptionDefault: String? = nil
    var serviceSpeechDefault: String? = nil
    var serviceSummarizationDefault: String? = nil

    func get(_ serviceID: String?) -> Service? {
        services.first(where: { $0.id == serviceID })
    }

    func update(config: Config) {
        self.services = config.services

        self.serviceChatDefault = config.serviceChatDefault
        self.serviceImageDefault = config.serviceImageDefault
        self.serviceEmbeddingDefault = config.serviceEmbeddingDefault
        self.serviceTranscriptionDefault = config.serviceTranscriptionDefault
        self.serviceSpeechDefault = config.serviceSpeechDefault
        self.serviceSummarizationDefault = config.serviceSummarizationDefault
    }

    func update(service: Service) {
        guard let index = services.firstIndex(where: { $0.id == service.id }) else { return }
        services[index] = service
        save()
    }

    func save() {
        Task {
            do {
                var config = API.shared.config
                config.services = services

                config.serviceChatDefault = serviceChatDefault
                config.serviceImageDefault = serviceImageDefault
                config.serviceEmbeddingDefault = serviceEmbeddingDefault
                config.serviceTranscriptionDefault = serviceTranscriptionDefault
                config.serviceSpeechDefault = serviceSpeechDefault
                config.serviceSummarizationDefault = serviceSummarizationDefault

                try await API.shared.configUpdate(config)
            } catch {
                print("[ServicesManager] Error: \(error)")
            }
        }
    }
}
