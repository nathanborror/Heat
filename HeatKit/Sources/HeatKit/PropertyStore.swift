import Foundation
import OSLog

private let logger = Logger(subsystem: "PropertyStore", category: "Kit")

public actor PropertyStore<T: Codable> {

    private var location: URL
    private var register: T? = nil

    public init(location: String) {
        let url = URL.documentsDirectory.appendingPathComponent(location)
        let dir = url.deletingLastPathComponent()
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.location = dir.appendingPathComponent(url.lastPathComponent, conformingTo: .propertyList)
    }

    public func write(_ register: T) throws {
        logger.debug("[PropertyStore] Saving \(self.location.absoluteString)")

        let data = try encoder.encode(register)
        try data.write(to: location, options: [.atomic])
        self.register = register
    }

    public func read() throws -> T? {
        logger.debug("[PropertyStore] Loading \(self.location.absoluteString)")

        let data = try Data(contentsOf: location)
        register = try decoder.decode(T.self, from: data)
        return register
    }

    private let encoder = {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return encoder
    }()

    private let decoder = PropertyListDecoder()
}
