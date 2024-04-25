/// Required Info.plist settings:
///     - NSCalendarsFullAccessUsageDescription
///     - NSRemindersFullAccessUsageDescription
///     - NSLocationWhenInUseUsageDescription

import SwiftUI
import UserNotifications
import EventKit
import CoreLocation
import HeatKit

struct PermissionsList: View {
    @Environment(Store.self) private var store
    
    @State var locationManager = LocationManager()
    
    var body: some View {
        @Bindable var store = store
        Form {
            Toggle("Notifications", isOn: Binding(
                get: { store.preferences.hasNotificationPermission },
                set: { shouldGetPermission in
                    if shouldGetPermission && !store.preferences.hasNotificationPermission {
                        requestNotificationPermission()
                    }
                }
            ))
            
            Toggle("Location", isOn: Binding(get: { store.preferences.hasLocationPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !store.preferences.hasLocationPermission {
                    requestLocationPermission()
                }
            }))
            
            Toggle("Calendar", isOn: Binding(get: { store.preferences.hasCalendarPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !store.preferences.hasCalendarPermission {
                    requestCalendarPermission()
                }
            }))
            
            Toggle("Reminders", isOn: Binding(get: { store.preferences.hasReminderPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !store.preferences.hasReminderPermission {
                    requestReminderPermission()
                }
            }))
        }
        .onAppear {
            getNotificationSettings()
            getLocationSettings()
            getCalendarSettings()
            getReminderSettings()
        }
        .onChange(of: locationManager.authorizationStatus) { _, newValue in
            getLocationSettings()
        }
    }
    
    // Notifications
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                store.preferences.hasNotificationPermission = true
            default:
                store.preferences.hasNotificationPermission = false
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            store.preferences.hasNotificationPermission = granted
        }
    }
    
    // Calendar
    
    func getCalendarSettings() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            store.preferences.hasCalendarPermission = true
        default:
            store.preferences.hasCalendarPermission = false
        }
    }
    
    func requestCalendarPermission() {
        EKEventStore().requestFullAccessToEvents { granted, error in
            store.preferences.hasCalendarPermission = granted
        }
    }
    
    // Reminders
    
    func getReminderSettings() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            store.preferences.hasReminderPermission = true
        default:
            store.preferences.hasReminderPermission = false
        }
    }
    
    func requestReminderPermission() {
        EKEventStore().requestFullAccessToReminders { granted, error in
            store.preferences.hasReminderPermission = granted
        }
    }
    
    // Location
    
    func getLocationSettings() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .restricted, .authorized, .authorizedWhenInUse:
            store.preferences.hasLocationPermission = true
        case .notDetermined, .denied:
            store.preferences.hasLocationPermission = false
        default:
            store.preferences.hasLocationPermission = false
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestAuthorization()
    }
}

#Preview {
    NavigationStack {
        PermissionsList()
    }
}
