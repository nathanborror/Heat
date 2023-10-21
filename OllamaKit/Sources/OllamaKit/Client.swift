import Foundation

final public class OllamaClient {
    
    let host: URL
    
    public init(host: String = "127.0.0.1:8080") {
        self.host = URL(string: "http://\(host)/api")!
    }
    
    public func generate(request: GenerateRequest) async throws -> GenerateResponse {
        var req = URLRequest(url: host.appending(path: "generate"))
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        var body = request
        body.stream = false
        req.httpBody = try JSONEncoder().encode(body)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let httpResponse = resp as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(GenerateResponse.self, from: data)
    }
    
    public func generateStream(request: GenerateRequest) -> AsyncThrowingStream<GenerateResponse, Error> {
        var buffer = Data()
        
        return AsyncThrowingStream { continuation in
            var req = URLRequest(url: host.appending(path: "generate"))
            req.httpMethod = "POST"
            req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            var body = request
            body.stream = true
            req.httpBody = try? JSONEncoder().encode(body)
            
            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                if let data = data {
                    buffer.append(data)
                    
                    while let range = buffer.range(of: "\n".data(using: .utf8)!) {
                        let lineData = buffer[..<range.lowerBound]
                        
                        do {
                            let item = try self.decoder.decode(GenerateResponse.self, from: lineData)
                            continuation.yield(item)
                        } catch {
                            continuation.finish(throwing: error)
                            return
                        }
                        
                        buffer.removeSubrange(..<range.upperBound)
                    }
                }
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
            }
            task.resume()
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    private var decoder: JSONDecoder {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}
