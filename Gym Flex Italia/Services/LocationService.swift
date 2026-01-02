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
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Location Updates
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .notAuthorized
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            error = .notAuthorized
            return
        }
        locationManager.requestLocation()
    }
    
    // MARK: - Smart Enable Handler
    
    /// Handles the "Enable" location button tap based on current permission state
    func handleEnableLocationTapped() {
        switch authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            openSystemSettings()
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
            requestOneTimeLocation()
        @unknown default:
            requestLocationPermission()
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
                print("📍 LocationService: Opened settings = \(success)")
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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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

