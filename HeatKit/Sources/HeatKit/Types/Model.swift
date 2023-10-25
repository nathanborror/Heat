import Foundation

public struct Model: Codable, Identifiable, Hashable {
    public var id: String { name }
    
    public var name: String
    public var size: Int64
    public var digest: String
    
    public var license: String?
    public var modelfile: String?
    public var parameters: String?
    public var template: String?
    public var system: String?
    
    init(name: String, size: Int64, digest: String,
         license: String? = nil, modelfile: String? = nil, parameters: String? = nil, template: String? = nil, system: String? = nil) {
        self.name = name
        self.size = size
        self.digest = digest
        
        self.license = license
        self.modelfile = modelfile
        self.parameters = parameters
        self.template = template
        self.system = system
    }
    
    public var supportsSystem: Bool {
        if modelfile?.contains("{{ .System }}") ?? false {
            return true
        }
        return false
    }
}

extension Model {
    
    public var family: String? {
        guard let first = name.split(separator: ":").first else { return nil }
        return String(first)
    }
}
