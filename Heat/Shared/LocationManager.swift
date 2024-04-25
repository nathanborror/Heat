import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        self.manager.delegate = self
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }
}
