import Foundation

protocol Persistence {
    func load<T: Codable>(objects: String) async throws -> [T]
    func load<T: Codable>(object filename: String) async throws -> T?
    
    func save<T: Codable>(filename: String, objects: [T]) async throws
    func save<T: Codable>(filename: String, object: T) async throws
    
    func delete(filename: String) throws
    func deleteAll() throws
}

final class MemoryPersistence: Persistence {
    
    static var shared = MemoryPersistence()
    
    func load<T: Codable>(objects: String) async throws -> [T]  {
        return []
    }
    
    func load<T: Codable>(object filename: String) async throws -> T?  {
        return nil
    }
    
    func save<T: Codable>(filename: String, objects: [T]) async throws  {}
    
    func save<T: Codable>(filename: String, object: T) async throws  {}
    
    func delete(filename: String) throws {}
    
    func deleteAll() throws {}
}

final class DiskPersistence: Persistence {

    static var shared = DiskPersistence()
    
    private init() {}
    
    var documents: URL? {
        try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }
    
    func load<T: Codable>(objects filename: String) async throws -> [T] {
        guard let url = documents?.appending(path: filename, directoryHint: .notDirectory) else {
            return []
        }
        let task = Task<[T], Error> {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        }
        return try await task.value
    }
    
    func load<T: Codable>(object filename: String) async throws -> T? {
        guard let url = documents?.appending(path: filename, directoryHint: .notDirectory) else {
            return nil
        }
        let task = Task<T?, Error> {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        }
        return try await task.value
    }

    func save<T: Codable>(filename: String, objects: [T]) async throws {
        guard let url = documents?.appending(path: filename, directoryHint: .notDirectory) else {
            return
        }
        let task = Task {
            let data = try JSONEncoder().encode(objects)
            try data.write(to: url)
        }
        _ = try await task.value
    }
    
    func save<T: Codable>(filename: String, object: T) async throws {
        guard let url = documents?.appending(path: filename, directoryHint: .notDirectory) else {
            return
        }
        let task = Task {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        }
        _ = try await task.value
    }
    
    func delete(filename: String) throws {
        guard let url = documents?.appending(path: filename, directoryHint: .notDirectory) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }
    
    func deleteAll() throws {
        guard let dir = documents else { return }
        print(dir)
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        for url in files {
            try FileManager.default.removeItem(at: url)
        }
    }
}
