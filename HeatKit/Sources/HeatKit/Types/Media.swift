import Foundation

public enum Media: Codable, Equatable, Hashable {
    case filesystem(String)
    case bundle(String)
    case video(String)
    case color(String)
    case data(Data)
    case systemIcon(String, String)
    case none
}
