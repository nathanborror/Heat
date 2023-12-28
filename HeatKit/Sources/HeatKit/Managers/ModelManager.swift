import Foundation
import OSLog
import OllamaKit

private let logger = Logger(subsystem: "ModelManager", category: "HeatKit")

public final class ModelManager {
    
    private var client: OllamaClient
    private var models: [Model]
    private var error: Error?
    
    public init(url: URL, models: [Model]) {
        self.client = OllamaClient(url: url)
        self.models = models
        self.error = nil
    }
    
    public func refresh() async -> Self {
        do {
            let resp = try await client.modelList()
            self.models = resp.models.map { Model(name: $0.name, size: $0.size, digest: $0.digest) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    public func details(for modelID: String) async -> Self {
        do {
            let payload = ModelShowRequest(name: modelID)
            let details = try await client.modelShow(payload)
            apply(details: details, modelID: modelID)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    public func pull(name: String, callback: (ProgressResponse) async -> Void) async -> Self {
        do {
            let payload = ModelPullRequest(name: name)
            for try await response in client.modelPull(payload) {
                await callback(response)
            }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    public func sink(callback: ([Model]) -> Void) async -> Self {
        await MainActor.run { callback(models) }
        return self
    }

    // MARK: Private
    
    private func apply(details: ModelShowResponse, modelID: String) {
        if let index = models.firstIndex(where: { $0.id == modelID }) {
            var existing = models[index]
            existing.license = details.license
            existing.modelfile = details.modelfile
            existing.parameters = details.parameters
            existing.template = details.template
            existing.system = details.system
            models[index] = existing
        }
    }
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("MessageManager Error: \(error, privacy: .public)")
            self.error = error
        }
    }
}
