import SwiftUI
import UserNotifications
import EventKit
import CoreLocation
import MusicKit
import HeatKit

struct PermissionsList: View {
    @Environment(Store.self) private var store
    
    @State var hasNotificationPermission = false    // NSLocationAlwaysAndWhenInUseUsageDescription
    @State var hasLocationPermission = false        // NSLocationWhenInUseUsageDescription
    @State var hasCalendarPermission = false        // NSCalendarsFullAccessUsageDescription
    @State var hasReminderPermission = false        // NSRemindersFullAccessUsageDescription
    @State var hasMusicPermission = false           // NSAppleMusicUsageDescription
    
    @State var locationManager = LocationManager()
    
    var body: some View {
        Form {
            Toggle("Notifications", isOn: Binding(
                get: { hasNotificationPermission },
                set: { shouldGetPermission in
                    if shouldGetPermission && !hasNotificationPermission {
                        requestNotificationPermission()
                    }
                }
            ))
            
            Toggle("Location", isOn: Binding(get: { hasLocationPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !hasLocationPermission {
                    requestLocationPermission()
                }
            }))
            
            Toggle("Calendar", isOn: Binding(get: { hasCalendarPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !hasCalendarPermission {
                    requestCalendarPermission()
                }
            }))
            
            Toggle("Reminders", isOn: Binding(get: { hasReminderPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !hasReminderPermission {
                    requestReminderPermission()
                }
            }))
            
            Toggle("Music", isOn: Binding(get: { hasMusicPermission }, set: { shouldGetPermission in
                if shouldGetPermission && !hasMusicPermission {
                    requestMusicPermission()
                }
            }))
        }
        .onAppear {
            getNotificationSettings()
            getLocationSettings()
            getCalendarSettings()
            getReminderSettings()
            getMusicSettings()
        }
        .onChange(of: locationManager.authorizationStatus) { _, newValue in
            getLocationSettings()
        }
    }
    
    // Notifications
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined, .denied:
                hasNotificationPermission = false
            case .authorized, .provisional, .ephemeral:
                hasNotificationPermission = true
            @unknown default:
                hasNotificationPermission = false
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            hasNotificationPermission = granted
        }
    }
    
    // Location
    
    func getLocationSettings() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .restricted, .authorized, .authorizedWhenInUse:
            hasLocationPermission = true
        case .notDetermined, .denied:
            hasLocationPermission = false
        @unknown default:
            hasLocationPermission = false
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestAuthorization()
    }
    
    // Calendar
    
    func getCalendarSettings() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined, .restricted, .denied:
            hasCalendarPermission = false
        case .fullAccess, .writeOnly, .authorized:
            hasCalendarPermission = true
        @unknown default:
            hasCalendarPermission = false
        }
    }
    
    func requestCalendarPermission() {
        EKEventStore().requestFullAccessToEvents { granted, error in
            hasCalendarPermission = granted
        }
    }
    
    // Reminders
    
    func getReminderSettings() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .notDetermined, .restricted, .denied:
            hasReminderPermission = false
        case .fullAccess, .writeOnly, .authorized:
            hasReminderPermission = true
        @unknown default:
            hasReminderPermission = false
        }
    }
    
    func requestReminderPermission() {
        EKEventStore().requestFullAccessToReminders { granted, error in
            hasReminderPermission = granted
        }
    }
    
    // Music
    
    func getMusicSettings() {
        switch MusicAuthorization.currentStatus {
        case .notDetermined, .denied, .restricted:
            hasMusicPermission = false
        case .authorized:
            hasMusicPermission = true
        @unknown default:
            hasMusicPermission = false
        }
    }
    
    func requestMusicPermission() {
        switch MusicAuthorization.currentStatus {
        case .authorized:
            hasMusicPermission = true
        default:
            Task {
                let status = await MusicAuthorization.request()
                switch status {
                case .notDetermined, .denied, .restricted:
                    hasMusicPermission = false
                case .authorized:
                    hasMusicPermission = true
                @unknown default:
                    hasMusicPermission = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PermissionsList()
    }
}
