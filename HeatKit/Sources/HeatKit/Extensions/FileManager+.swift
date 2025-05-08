import Foundation

extension FileManager {

    public func list(contentsOf directoryURL: URL, ignore: [String] = [], options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]) throws -> [URL] {
        try createDirectoryIfNeeded(at: directoryURL)
        let urls = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: options)
        return urls.filter { !ignore.contains($0.lastPathComponent) }
    }

    public func moveItem(at sourceURL: URL, to destinationURL: URL, createDirectories: Bool) throws {
        try createDirectoryIfNeeded(at: destinationURL)
        try moveItem(at: sourceURL, to: destinationURL)
    }

    public func createDirectoryIfNeeded(at url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            let directoryURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }

    public func removeItems(at url: URL) throws {
        let urls = try list(contentsOf: url)
        for url in urls {
            try FileManager.default.removeItem(at: url)
        }
    }
}
