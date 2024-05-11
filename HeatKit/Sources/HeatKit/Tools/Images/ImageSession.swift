import Foundation
import OSLog
import SharedKit
import GenKit

private let logger = Logger(subsystem: "ImageSession", category: "HeatKit")

public final class ImageSession {
    public typealias ManagerCallback = @MainActor (ImageSession) -> Void
    public typealias ImagesCallback = @MainActor ([Data]) -> Void
    
    public static let shared = ImageSession()
    
    public private(set) var error: Error?

    private init() {}
    
    @discardableResult
    public func manage(callback: ManagerCallback) async -> Self {
        await callback(self)
        return self
    }
    
    @discardableResult
    public func generate(service: ImageService, model: String, prompt: String, callback: ImagesCallback) async -> Self {
        do {
            try Task.checkCancellation()
            let req = ImagineServiceRequest(model: model, prompt: prompt)
            let images = try await service.imagine(request: req)
            await callback(images)
        } catch {
            apply(error: error)
        }
        return self
    }
    
    // Private
    
    private func apply(error: Error?) {
        if let error = error {
            logger.error("ImageSession Error: \(error, privacy: .public)")
            self.error = error
        }
    }
}
