import Foundation
import OSLog

public actor DataStore<Register: Codable> {

    private var location: URL
    private var register: Register? = nil

    enum Error: Swift.Error, CustomStringConvertible {
        case encodingError(String)
        case decodingError(String)

        public var description: String {
            switch self {
            case .encodingError(let detail):
                "Encoding error: \(detail)"
            case .decodingError(let detail):
                "Decoding error: \(detail)"
            }
        }
    }

    public init(location: String) {
        let url = URL.documentsDirectory.appendingPathComponent(location)
        let dir = url.deletingLastPathComponent()
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.location = dir.appendingPathComponent(url.lastPathComponent, conformingTo: .propertyList)
    }

    public func write(_ register: Register) throws {
        do {
            let data = try encoder.encode(register)
            try data.write(to: location, options: [.atomic])
            self.register = register
        } catch {
            throw Error.encodingError(error.localizedDescription)
        }
    }

    public func read() throws -> Register? {
        do {
            let data = try Data(contentsOf: location)
            register = try decoder.decode(Register.self, from: data)
            return register
        } catch {
            throw Error.decodingError(error.localizedDescription)
        }
    }

    private let encoder = {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return encoder
    }()

    private let decoder = PropertyListDecoder()
}
