import Foundation

public struct ModelListResponse: Codable {
    public let models: [ModelResponse]
}

public struct ModelResponse: Codable {
    public let name: String
    public let size: Int64
    public let digest: String
}

public struct ModelShowRequest: Codable {
    public var name: String
}

public struct ModelShowResponse: Codable {
    public let license: String?
    public let modelfile: String?
    public let parameters: String?
    public let template: String?
    public let system: String?
}

public struct ModelCreateRequest: Codable {
    public var name: String
    public var path: String
    public var stream: Bool?
}

public struct ModelDeleteRequest: Codable {
    public var name: String
}

public struct ModelCopyRequest: Codable {
    public var source: String
    public var destination: String
}

public struct ModelPullRequest: Codable {
    public var name: String
    public var insecure: Bool?
    public var username: String
    public var password: String
    public var stream: Bool?
}

public struct ModelPushRequest: Codable {
    public var name: String
    public var insecure: Bool?
    public var username: String
    public var password: String
    public var stream: Bool?
}

public struct ProgressResponse: Codable {
    public let status: String
    public let digest: String?
    public let total: Int64?
    public let completed: Int64?
}
