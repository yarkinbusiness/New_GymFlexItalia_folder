//
//  LocationService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import CoreLocation
import Combine
import UIKit

/// Location service for user location tracking
final class LocationService: NSObject, ObservableObject {
    
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Authorization
    
    /// Refresh the authorization status from the location manager
    @MainActor
    func refreshAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        
        #if DEBUG
        print("📍 LocationService.refreshAuthorizationStatus -> \(authorizationStatusName)")
        #endif
    }
    
    /// Request location permission (shows iOS prompt if notDetermined)
    @MainActor
    func requestLocationPermission() {
        #if DEBUG
        print("📍 LocationService.requestLocationPermission called")
        #endif
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Check if location is authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Human-readable authorization status name (for debugging)
    private var authorizationStatusName: String {
        switch authorizationStatus {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown(\(authorizationStatus.rawValue))"
        }
    }
    
    // MARK: - Location Updates
    
    func startUpdatingLocation() {
        guard isAuthorized else {
            error = .notAuthorized
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() {
        guard isAuthorized else {
            error = .notAuthorized
            return
        }
        locationManager.requestLocation()
    }
    
    // MARK: - Smart Enable Handler
    
    /// Handles the "Enable" location button tap based on current permission state
    @MainActor
    func handleEnableLocationTapped() {
        // Always refresh status first to ensure we have the latest
        refreshAuthorizationStatus()
        
        #if DEBUG
        print("📍 LocationService.enableTap status=\(authorizationStatusName)")
        #endif
        
        switch authorizationStatus {
        case .notDetermined:
            // Show iOS permission prompt
            requestLocationPermission()
            
        case .denied, .restricted:
            // Open iOS Settings for this app
            openSystemSettings()
            
        case .authorizedAlways, .authorizedWhenInUse:
            // Already authorized - fetch location immediately
            startUpdatingLocation()
            requestOneTimeLocation()
            
        @unknown default:
            requestLocationPermission()
        }
    }
    
    /// Start location updates if already authorized (safe to call repeatedly)
    /// Use this when returning from Settings or on app foreground
    @MainActor
    func startIfAuthorized() {
        refreshAuthorizationStatus()
        
        #if DEBUG
        print("📍 LocationService.startIfAuthorized status=\(authorizationStatusName)")
        #endif
        
        if isAuthorized {
            startUpdatingLocation()
            requestOneTimeLocation()
        }
    }
    
    /// Opens iOS Settings for this app
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            print("⚠️ LocationService: Invalid settings URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                #if DEBUG
                print("📍 LocationService: Opened settings = \(success)")
                #endif
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func distance(from coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: location)
    }
    
    func formattedDistance(from coordinate: CLLocationCoordinate2D) -> String? {
        guard let distance = distance(from: coordinate) else { return nil }
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        #if DEBUG
        print("📍 LocationService.didChangeAuthorization -> \(authorizationStatusName)")
        #endif
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            error = nil
            startUpdatingLocation()
        case .denied, .restricted:
            error = .notAuthorized
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        error = nil
        
        #if DEBUG
        print("📍 LocationService.didUpdateLocations -> \(location.coordinate.latitude),\(location.coordinate.longitude)")
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("📍 LocationService.didFailWithError: \(error.localizedDescription)")
        #endif
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                self.error = .notAuthorized
            case .network:
                self.error = .networkError
            default:
                self.error = .unknown
            }
        }
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case notAuthorized
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access not authorized"
        case .networkError:
            return "Network error while fetching location"
        case .unknown:
            return "Unknown location error"
        }
    }
}
