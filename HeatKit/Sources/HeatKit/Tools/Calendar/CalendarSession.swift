import Foundation
import EventKit

public class CalendarSession {
    public static let shared = CalendarSession()
    
    private init() {}
    
    /// Returns events between two dates, a start date which is typically Date.now() and a future end date.
    public func events(between start: Date, end: Date) throws -> [EKEvent] {
        guard hasAccess else { throw CalendarSessionError.missingAccess }
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
    
    public func events(between start: String, end: String) throws -> [EKEvent] {
        guard
            let start = Date(string: start, format: "yyyy-MM-dd"),
            let end = Date(string: end, format: "yyyy-MM-dd") else { return [] }
        return try events(between: start, end: end)
    }
    
    // MARK: Private
    
    private var hasAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            return true
        default:
            return false
        }
    }
}

enum CalendarSessionError: Error {
    case missingAccess
}
