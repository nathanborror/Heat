import Foundation

class SpotlightManager {
    
    public init() {}
    
    public enum Kind: String, CaseIterable {
        case application
        case audio
        case bookmark
        case contact
        case email
        case folder
        case font
        case events
        case todo
        case image
        case movie
        case pdf
        case preferences
        case presentation
    }
    
    public func query(_ str: String, kind: Kind? = nil) throws -> [String] {
        #if os(macOS)
        let task = Process()
        let pipe = Pipe()
        
        var query = str
        if let kind {
            query = "kind:\(kind.rawValue) \(query)"
        }
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "mdfind \(query)"]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh") // or "/bin/bash" for Bash
        task.standardInput = nil
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
            return lines.map { String($0) }
        }
        return []
        #else
        return ["Only works on MacOS"]
        #endif
    }
}
