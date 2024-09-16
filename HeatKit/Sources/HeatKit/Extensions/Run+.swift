import Foundation
import GenKit

extension Run {
    
    public var steps: [Message] {
        Array(messages.dropLast())
    }
    
    public var elapsed: TimeInterval? {
        guard let ended else { return nil }
        let elapsed = ended.timeIntervalSince(started)
        return elapsed
    }
    
    public var elapsedPretty: String? {
        guard let elapsed else { return nil }
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = (Int(elapsed) % 3600) % 60
        if minutes == 0 {
            return "\(seconds) seconds"
        }
        return "\(minutes) minutes, \(seconds) seconds"
    }
    
    public var response: Message? {
        guard
            let message = messages.last,
            message.role == .assistant,
            message.toolCalls == nil
        else { return nil }
        return message
    }
}
