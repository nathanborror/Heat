import Foundation
import RegexBuilder
import GenKit

public final class Parser {
    public static let shared = Parser()
    
    private let tagPattern = #/<(?<name>[^>\s]+)(?<params>\s+[^>]+)?>(?<content>.*?)(?:<\/\k<name>>|$)/#
    private let tagParamsPattern = #/(?<name>\w+)="(?<value>[^"]*)"/#
    
    private init() {}
    
    public func parse(input: String, tags: [String] = []) throws -> ParserResult {
        if tags.isEmpty {
            return try parseAll(input: input)
        }
        
        var parsedTags: [ParserResult.Tag] = []
        
        let output = try input.replacing(tagPattern.dotMatchesNewlines()) { match in
            guard tags.contains(String(match.output.name)) else {
                return match.output.0
            }
            
            let name = String(match.output.name)
            let content = String(match.output.content)
            
            parsedTags.append(
                .init(
                    name: name,
                    content: content,
                    params: try parseTagParams(match.output.params)
                )
            )
            return "<\(name) />"
        }
        return .init(tags: parsedTags, text: output)
    }
    
    public func parseAll(input: String) throws -> ParserResult {
        var parsedTags: [ParserResult.Tag] = []
        let output = try input.replacing(tagPattern.dotMatchesNewlines()) { match in
            let name = String(match.output.name)
            let content = String(match.output.content)
            
            parsedTags.append(
                .init(
                    name: name,
                    content: content,
                    params: try parseTagParams(match.output.params)
                )
            )
            return "<\(name) />"
        }
        return .init(tags: parsedTags, text: output)
    }

    private func parseTagParams(_ input: Substring?) throws -> [String: String] {
        guard let input else { return [:] }
        let matches = input.matches(of: tagParamsPattern)
        var out: [String: String] = [:]
        for match in matches {
            let (_, name, value) = match.output
            out[String(name)] = String(value)
        }
        return out
    }
}

public struct ParserResult {
    public var tags: [Tag] = []
    public var text: String = ""
    
    public struct Tag {
        public var name: String
        public var content: String? = nil
        public var params: [String: String] = [:]
    }
}
