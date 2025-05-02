/*
 ___   ___   ______   ________   _________
/__/\ /__/\ /_____/\ /_______/\ /________/\
\::\ \\  \ \\::::_\/_\::: _  \ \\__.::.__\/
 \::\/_\ .\ \\:\/___/\\::(_)  \ \  \::\ \
  \:: ___::\ \\::___\/_\:: __  \ \  \::\ \
   \: \ \\::\ \\:\____/\\:.\ \  \ \  \::\ \
    \__\/ \::\/ \_____\/ \__\/\__\/   \__\/
 */

import SwiftUI
import OSLog
import HeatKit
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "AppState", category: "App")

@MainActor @Observable
final class AppState {

    static let shared = AppState()

    enum Error: Swift.Error, CustomStringConvertible {
        case restorationError(String)
        case serviceError(String)

        public var description: String {
            switch self {
            case .restorationError(let detail):
                "Restoration error: \(detail)"
            case .serviceError(let detail):
                "Service error: \(detail)"
            }
        }
    }

    var selectedFileID: String? = nil

    // Providers oversee a specific top-level kind of data and provide methods
    // for mutating and storing the data they're responsible for.

    private let filesProvider: FilesProvider
    private let logsProvider: LogsProvider

    // Shortcuts

    var areModelsAvailable: Bool {
        API.shared.config.serviceChatDefault != nil
    }

    var config: Config {
        filesProvider.config
    }

    var files: [File] {
        filesProvider.files
    }

    var fileTree: [FileTree] {
        let files = try? API.shared.fileListTree()
        return files ?? []
    }

    var instructions: [File] {
        filesProvider.files.filter { $0.isInstruction }
    }

    var logs: [Log] {
        logsProvider.logs
    }

    private init() {
        self.filesProvider = .shared
        self.logsProvider = .shared

        logger.info("🍱 \(URL.documentsDirectory.path())")

        Task { try await ready() }
    }

    func restore() async throws {
        try await filesProvider.restore()
        try await logsProvider.restore()
    }

    func ready() async throws {
        async let filesReady: Void = filesProvider.ready()
        async let logsReady: Void = logsProvider.ready()
        _ = try await [filesReady, logsReady]
    }

    @discardableResult
    func ping() async throws -> Bool {
        try await ready()
        return true
    }

    func resetAll() {
        do {
            // Reset providers
            filesProvider.reset()
            logsProvider.reset()

            // Delete all files
            try FileManager.default.removeItems(at: URL.documentsDirectory)

            // Create default instruction files
            Task {
                for (id, name, instruction) in Defaults.instructions {
                    let _ = try await fileCreateInstruction(id: id, name: name, instruction: instruction)
                }
            }
        } catch {
            log(error: error)
        }
    }

    // MARK: - File Handling

    func file<T: Decodable>(_ type: T.Type, fileID: String) throws -> T {
        try filesProvider.cachedFileObject(type, fileID: fileID)
    }

    func folderCreate(id: String = .id) async throws -> String {
        let filename = "\(id)"
        let fileID = try await fileCreate(id: id, filename: filename, mimetype: .directory)
        selectedFileID = fileID
        return fileID
    }

    func fileCreateConversation(id: String = .id) async throws -> String {
        let instruction = try filesProvider.cachedFileObject(Instruction.self, fileID: Defaults.instructionAssistantID)
        let object = Conversation(
            instructions: instruction.instructions,
            toolIDs: instruction.toolIDs
        )
        let filename = "\(id).conversation"
        let fileID = try await fileCreate(id: id, filename: filename, mimetype: .json, object: object)
        selectedFileID = fileID
        return fileID
    }

    func fileCreateDocument(id: String = .id) async throws -> String {
        let object = Document()
        let filename = "\(id).document"
        let fileID = try await fileCreate(id: id, filename: filename, mimetype: .json, object: object)
        selectedFileID = fileID
        return fileID
    }

    func fileCreateInstruction(id: String = .id, name: String, instruction: Instruction) async throws -> String {
        let object = instruction
        let filename = "\(id).instruction"
        let fileID = try await fileCreate(id: id, filename: filename, path: ".app/instructions/\(filename)", name: name, mimetype: .json, object: object)
        return fileID
    }

    func fileUpdate(_ object: any Encodable, fileID: String) async throws {
        try await filesProvider.cacheFileObject(object, fileID: fileID)
    }

    private func fileCreate(id: String, filename: String, path: String? = nil, name: String? = nil, mimetype: UTType, object: any Encodable) async throws -> String {
        let directory = try currentFilePath()
        let path = path ?? directory?.appending(path: filename).path ?? filename
        let file = File(id: id, path: path, name: name, mimetype: mimetype)
        return try await API.shared.fileCreate(file, object: object)
    }

    private func fileCreate(id: String, filename: String, path: String? = nil, name: String? = nil, mimetype: UTType) async throws -> String {
        let directory = try currentFilePath()
        let path = path ?? directory?.appending(path: filename).path ?? filename
        let file = File(id: id, path: path, name: name, mimetype: mimetype)
        return try await API.shared.fileCreate(file)
    }

    private func currentFilePath() throws -> URL? {
        guard let fileID = selectedFileID, let file = try? API.shared.file(fileID) else {
            return nil
        }
        if file.isDirectory {
            return URL(string: file.path)
        }
        guard let parentFilePath = URL(string: file.path)?.deletingLastPathComponent().path else {
            return nil
        }
        guard parentFilePath != "." else {
            return nil
        }
        return URL(string: parentFilePath)
    }

    // MARK: - Logging

    func log(error: Swift.Error) {
        logsProvider.log(error: error)
    }

    func logsReset() {
        logsProvider.reset()
    }
}
