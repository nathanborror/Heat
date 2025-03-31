import Foundation

extension Data {

    public func write(to url: URL, options: Data.WritingOptions = [], createDirectories: Bool) throws {
        let directoryURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try write(to: url, options: options)
    }
}
