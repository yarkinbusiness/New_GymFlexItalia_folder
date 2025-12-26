//
//  DashboardViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

/// ViewModel for the main dashboard
@MainActor
final class DashboardViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var nearbyGyms: [Gym] = []
    @Published var recentBookings: [Booking] = []
    @Published var activeBooking: Booking?
    @Published var userLocation: CLLocation?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var lastBookedGym: Gym?
    
    private let gymsService = GymsService.shared
    private let bookingService = BookingService.shared
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        // If we haven't loaded gyms yet, load them now that we have location
        if nearbyGyms.isEmpty {
            Task {
                await fetchNearbyGyms()
            }
        }
    }
    
    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchNearbyGyms() }
            group.addTask { await self.fetchRecentBookings() }
        }
    }
    
    func refreshData() async {
        await loadDashboard()
    }
    
    private func fetchNearbyGyms() async {
        do {
            let coordinate = userLocation?.coordinate
            var gyms = try await gymsService.fetchGyms(near: coordinate)
            
            // Sort by distance if location is available
            if let userLoc = userLocation {
                gyms.sort { gym1, gym2 in
                    let loc1 = CLLocation(latitude: gym1.latitude, longitude: gym1.longitude)
                    let loc2 = CLLocation(latitude: gym2.latitude, longitude: gym2.longitude)
                    return userLoc.distance(from: loc1) < userLoc.distance(from: loc2)
                }
            }
            
            self.nearbyGyms = gyms
        } catch {
            print("Failed to fetch nearby gyms: \(error.localizedDescription)")
        }
    }
    
    private func fetchRecentBookings() async {
        do {
            let bookings = try await bookingService.fetchBookings()
            self.recentBookings = bookings.sorted { $0.startTime > $1.startTime }
            
            // Check for active booking (active or upcoming)
            var foundBooking: Booking?
            for booking in bookings {
                if booking.status == .checkedIn || booking.status == .confirmed {
                    foundBooking = booking
                    break
                }
            }
            self.activeBooking = foundBooking
            
            // Find last booked gym
            if let lastBooking = bookings.first(where: { $0.status == .completed }),
               let gymId = lastBooking.gymName { // Using gymName as ID for now or fetch gym
                   // In a real app we would fetch the full gym object.
                   // For now, we'll try to find it in nearbyGyms or create a partial one
                   if let gym = nearbyGyms.first(where: { $0.name == gymId }) {
                       self.lastBookedGym = gym
                   } else {
                       // Fallback or fetch specific gym
                       // For this task, we just need the name for the UI
                       // We will store a partial gym or just use the name in the view
                   }
            }
            
        } catch {
            print("Failed to fetch recent bookings: \(error.localizedDescription)")
        }
    }
    
    func createBooking(gymId: String, duration: Int) async -> Booking? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let booking = try await bookingService.createBooking(
                gymId: gymId,
                startTime: Date(),
                duration: duration
            )
            
            // Update BookingManager for app-wide access
            BookingManager.shared.setActiveBooking(booking)
            
            await refreshData() // Refresh to update active booking
            return booking
        } catch {
            self.errorMessage = error.localizedDescription
            return nil
        }
    }
}
