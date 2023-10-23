import Foundation

public struct EmbeddingRequest: Codable {
    public var model: String
    public var prompt: String
    public var options: [String: AnyValue]
}

public struct EmbeddingResponse: Codable {
    public let embedding: [Float64]
}
