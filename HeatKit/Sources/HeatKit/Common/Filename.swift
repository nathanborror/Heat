import Foundation

public enum Filename {
    case document(String)
    case cache(String)
    case bundle(String)
    
    public var url: URL? {
        switch self {
        case .document(let filename):
            return documents?.appendingPathComponent(filename)
        case .cache(let filename):
            return caches?.appendingPathComponent(filename)
        case .bundle(let filename):
            let (name, ext) = splitFilename(filename)
            return Bundle.main.url(forResource: name, withExtension: ext)
        }
    }
    
    public var name: String {
        switch self {
        case .document(let filename):
            filename
        case .cache(let filename):
            filename
        case .bundle(let filename):
            filename
        }
    }
    
    private func splitFilename(_ filename: String) -> (String, String) {
        let url = URL(fileURLWithPath: filename)
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        return (name, ext)
    }
}

private let documents: URL? =
    try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

private let caches: URL? =
    try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
