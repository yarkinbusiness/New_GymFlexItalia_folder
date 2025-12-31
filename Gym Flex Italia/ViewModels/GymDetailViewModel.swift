//
//  GymDetailViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import CoreLocation
import Combine
import UIKit

/// ViewModel for gym detail view
@MainActor
final class GymDetailViewModel: ObservableObject {
    
    @Published var gym: Gym?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showBookingForm = false
    @Published var bookingConfirmation: BookingConfirmation?
    
    private let gymsService = GymsService.shared
    private let locationService = LocationService.shared
    
    // MARK: - Load Gym
    func loadGym(gymId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            gym = try await gymsService.fetchGym(id: gymId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Load gym using injected service (preferred for production)
    func loadGym(gymId: String, using service: GymServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        bookingConfirmation = nil
        
        do {
            gym = try await service.fetchGymDetail(id: gymId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Book the current gym using injected service
    func bookGym(date: Date, duration: Int, using service: BookingServiceProtocol) async -> Bool {
        guard let gymId = gym?.id else {
            errorMessage = "No gym selected"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let confirmation = try await service.createBooking(gymId: gymId, date: date, duration: duration)
            bookingConfirmation = confirmation
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Distance
    var distanceFromUser: String? {
        guard let gym = gym,
              let userLocation = locationService.currentLocation else {
            return nil
        }
        
        let distance = gym.distance(from: userLocation)
        
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    // MARK: - Opening Hours
    func isOpenNow() -> Bool {
        guard let hours = gym?.openingHours else { return false }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        let dayHours: OpeningHours.DayHours? = {
            switch weekday {
            case 1: return hours.sunday
            case 2: return hours.monday
            case 3: return hours.tuesday
            case 4: return hours.wednesday
            case 5: return hours.thursday
            case 6: return hours.friday
            case 7: return hours.saturday
            default: return nil
            }
        }()
        
        guard let dayHours = dayHours, !dayHours.isClosed else {
            return false
        }
        
        // Parse hours and check if current time is within range
        // This is a simplified check - production would need better time parsing
        return true
    }
    
    var openingStatusText: String {
        if isOpenNow() {
            return "Open Now"
        } else {
            return "Closed"
        }
    }
    
    // MARK: - Actions
    func bookGym() {
        showBookingForm = true
    }
    
    func callGym() {
        guard let phoneNumber = gym?.phoneNumber,
              let url = URL(string: "tel://\(phoneNumber)") else {
            return
        }
        
        #if !targetEnvironment(simulator)
        UIApplication.shared.open(url)
        #endif
    }
    
    func openWebsite() {
        guard let website = gym?.website,
              let url = URL(string: website) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    func getDirections() {
        guard let gym = gym else { return }
        
        let coordinates = "\(gym.latitude),\(gym.longitude)"
        let urlString = "http://maps.apple.com/?daddr=\(coordinates)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func createBooking(duration: Int) async -> Bool {
        guard let gymId = gym?.id else { return false }
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await BookingService.shared.createBooking(
                gymId: gymId,
                startTime: Date(),
                duration: duration
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

