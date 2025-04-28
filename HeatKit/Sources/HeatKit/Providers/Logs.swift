import Foundation

public struct Log: Codable, Identifiable {
    public let id: String
    public let kind: Kind
    public let message: String
    public let created: Date

    public enum Kind: String, Codable {
        case error
        case info
        case warning
    }

    public init(kind: Kind, message: String) {
        self.id = .id
        self.kind = kind
        self.message = message
        self.created = .now
    }
}

@MainActor @Observable
public final class LogsProvider {
    public static let shared = LogsProvider()

    public private(set) var logs: [Log] = []

    private let persistenceURL = URL.documentsDirectory.appending(path: ".logs")
    private var persistenceRestoration: Task<Void, Swift.Error>?

    public init() {
        self.persistenceRestoration = Task { try await restore() }
    }

    public func ready() async throws {
        try await persistenceRestoration?.value
    }

    public func restore() async throws {
        do {
            let data = try Data(contentsOf: persistenceURL)
            self.logs = try decoder.decode([Log].self, from: data)
        } catch {
            print("Failed to restore logs (likely doesn't exist)")
        }
    }

    public func reset() {
        logs = []
        save()
    }

    public func save() {
        do {
            let data = try encoder.encode(logs)
            try data.write(to: persistenceURL, options: .atomic, createDirectories: true)
        } catch {
            print(error)
        }
    }

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let encoder = JSONDecoder()
        return encoder
    }()
}

extension LogsProvider {

    public func log(info message: String) {
        log(.init(kind: .info, message: message))
    }

    public func log(warning message: String) {
        log(.init(kind: .warning, message: message))
    }

    public func log(error: Swift.Error) {
        log(.init(kind: .error, message: "\(error)"))
    }

    private func log(_ log: Log) {
        logs.append(log)
        save()
    }
}
