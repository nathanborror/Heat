import Foundation
import EventKit

public class CalendarManager {
    
    public init() {}
    
    /// Returns events between two dates, a start date which is typically Date.now() and a future end date.
    public func events(between start: Date, end: Date) -> [EKEvent] {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
    
    public func events(between start: String, end: String) -> [EKEvent] {
        guard
            let start = Date(string: start, format: "yyyy-MM-dd"),
            let end = Date(string: end, format: "yyyy-MM-dd") else { return [] }
        return events(between: start, end: end)
    }
}
