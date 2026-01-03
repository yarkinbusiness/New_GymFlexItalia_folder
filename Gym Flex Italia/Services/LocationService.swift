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

/// Location issue states for UI guidance
enum LocationIssue: Equatable {
    case notDetermined          // User hasn't responded to permission prompt yet
    case deniedOrRestricted     // User denied or system restricted
    case authorizedButNoFix     // Authorized but can't get location (Ask Next Time, no GPS, simulator)
    
    var userGuidance: String {
        switch self {
        case .notDetermined:
            return "Enable location to see nearby gyms"
        case .deniedOrRestricted:
            return "Location access denied. Please enable in Settings."
        case .authorizedButNoFix:
            return "Location is allowed, but we can't get a fix. Please set Location to 'While Using the App' in Settings."
        }
    }
    
    var buttonLabel: String {
        switch self {
        case .notDetermined:
            return "Enable Location"
        case .deniedOrRestricted, .authorizedButNoFix:
            return "Open Settings"
        }
    }
}

/// Location service for user location tracking
final class LocationService: NSObject, ObservableObject {
    
    static let shared = LocationService()
    
    // MARK: - Published State
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?
    
    /// Current location issue requiring user action (nil = no issue)
    @Published var locationIssue: LocationIssue? = nil
    
    /// Timestamp of last successful location fix
    @Published var lastFixDate: Date? = nil
    
    /// Debug: source of last fix (for logging)
    var lastFixSource: String? = nil
    
    // MARK: - Private
    
    private let locationManager = CLLocationManager()
    private var retryTask: Task<Void, Never>? = nil
    
    private override init() {
        super.init()
        
        // CRITICAL: Set delegate once, strongly retained
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        authorizationStatus = locationManager.authorizationStatus
        updateLocationIssue()
        
        #if DEBUG
        // Verify Info.plist has location usage description
        let hasLocationKey = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
        print("📍 LocationService.init: status=\(authorizationStatusName)")
        print("📍 INFO_PLIST has NSLocationWhenInUseUsageDescription: \(hasLocationKey)")
        print("📍 LocationManager delegate set: \(locationManager.delegate != nil)")
        
        if !hasLocationKey {
            print("⚠️⚠️⚠️ CRITICAL: NSLocationWhenInUseUsageDescription missing from Info.plist!")
            print("⚠️⚠️⚠️ iOS will NOT show the location permission prompt without this key!")
        }
        #endif
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
        print("📍 LocationService.requestLocationPermission called (current status: \(authorizationStatusName))")
        print("📍 Requesting auth on main thread: \(Thread.isMainThread)")
        #endif
        
        // Only request if not determined - otherwise prompt won't show
        if authorizationStatus == .notDetermined {
            print("📍 LocationService: Calling requestWhenInUseAuthorization NOW...")
            locationManager.requestWhenInUseAuthorization()
            print("📍 LocationService: requestWhenInUseAuthorization sent to iOS")
        } else {
            print("📍 LocationService: Permission already determined (\(authorizationStatusName)), skipping request")
        }
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
    
    /// Update the locationIssue based on current state
    @MainActor
    private func updateLocationIssue() {
        switch authorizationStatus {
        case .notDetermined:
            locationIssue = .notDetermined
        case .denied, .restricted:
            locationIssue = .deniedOrRestricted
        case .authorizedWhenInUse, .authorizedAlways:
            // Authorized - check if we have a location
            if currentLocation != nil {
                locationIssue = nil  // All good!
            } else {
                // Authorized but no location yet - don't set authorizedButNoFix immediately
                // Let ensureFreshLocation handle the retry logic
                locationIssue = nil  // Will be set by ensureFreshLocation if retries fail
            }
        @unknown default:
            locationIssue = nil
        }
        
        #if DEBUG
        if let issue = locationIssue {
            print("📍 LocationService.updateLocationIssue: \(issue)")
        } else {
            print("📍 LocationService.updateLocationIssue: nil (no issue)")
        }
        #endif
    }
    
    // MARK: - Resilient Location Acquisition
    
    /// Ensure we have a fresh location, with retry logic
    /// Call this on view appear, scene active, and after authorization changes
    @MainActor
    func ensureFreshLocation(reason: String) async {
        // Cancel any existing retry task
        retryTask?.cancel()
        
        #if DEBUG
        print("📍 LocationService.ensureFreshLocation(reason: \(reason)) status=\(authorizationStatusName) hasLocation=\(currentLocation != nil)")
        #endif
        
        // Refresh authorization status first
        refreshAuthorizationStatus()
        updateLocationIssue()
        
        // If not authorized, nothing to do
        guard isAuthorized else {
            #if DEBUG
            print("📍 LocationService.ensureFreshLocation: Not authorized, returning")
            #endif
            return
        }
        
        // Start location updates and request one-time location
        startUpdatingLocation()
        requestOneTimeLocation()
        
        // Wait 2 seconds for location to arrive
        retryTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            if Task.isCancelled { return }
            
            if currentLocation == nil {
                #if DEBUG
                print("📍 LocationService.ensureFreshLocation: No location after 2s, retrying...")
                #endif
                
                // Retry once
                requestOneTimeLocation()
                
                // Wait another 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                if Task.isCancelled { return }
                
                if currentLocation == nil {
                    // Still no location - set authorizedButNoFix issue
                    #if DEBUG
                    print("📍 LocationService.ensureFreshLocation: Still no location after retry, setting authorizedButNoFix")
                    #endif
                    locationIssue = .authorizedButNoFix
                }
            }
        }
    }
    
    // MARK: - Location Updates
    
    func startUpdatingLocation() {
        #if DEBUG
        print("📍 LocationService.startUpdatingLocation called (authorized: \(isAuthorized))")
        #endif
        
        guard isAuthorized else {
            error = .notAuthorized
            print("📍 LocationService.startUpdatingLocation: NOT authorized, aborting")
            return
        }
        locationManager.startUpdatingLocation()
        print("📍 LocationService.startUpdatingLocation: Location updates STARTED")
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() {
        #if DEBUG
        print("📍 LocationService.requestOneTimeLocation called (authorized: \(isAuthorized))")
        #endif
        
        guard isAuthorized else {
            error = .notAuthorized
            return
        }
        locationManager.requestLocation()
        print("📍 LocationService.requestOneTimeLocation: One-time request sent")
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
        
        // Update location issue state
        Task { @MainActor in
            updateLocationIssue()
        }
        
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
        lastFixDate = Date()
        lastFixSource = "didUpdateLocations"
        
        #if DEBUG
        print("📍 LocationService.didUpdateLocations -> \(location.coordinate.latitude),\(location.coordinate.longitude) at \(lastFixDate!)")
        #endif
        
        // Clear any location issue since we now have a fix
        Task { @MainActor in
            locationIssue = nil
            print("📍 LocationService: Location fix received, cleared locationIssue")
        }
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
            case .locationUnknown:
                // Location can't be determined - device issue or simulator
                #if DEBUG
                print("📍 LocationService: CLError.locationUnknown - may be simulator or no GPS")
                #endif
                // If authorized but can't get location, set the issue
                if isAuthorized && currentLocation == nil {
                    Task { @MainActor in
                        locationIssue = .authorizedButNoFix
                    }
                }
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
