import Foundation
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "MediaManager", category: "MateKit")

public final class MediaManager {
    public private(set) var error: Error?

    public init() {}
    
    @discardableResult
    public func manage(callback: (MediaManager) -> Void) async -> Self {
        await MainActor.run { callback(self) }
        return self
    }
    
    @discardableResult
    public func generate(service: ImageService, model: String, prompt: String, callback: ([Data]) -> Void) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let images = try await service.imagine(request: req)
            await MainActor.run { callback(images) }
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Private
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("MediaManager Error: \(error, privacy: .public)")
            self.error = error
        }
    }
}
