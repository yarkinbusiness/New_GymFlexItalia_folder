//
//  BookingViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import Combine

/// ViewModel for booking management
@MainActor
final class BookingViewModel: ObservableObject {
    
    @Published var selectedGym: Gym?
    @Published var selectedDate = Date()
    @Published var selectedDuration = 60 // minutes
    @Published var availableSlots: [AvailabilitySlot] = []
    
    @Published var currentBooking: Booking?
    @Published var bookings: [Booking] = []
    @Published var upcomingBookings: [Booking] = []
    @Published var pastBookings: [Booking] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showConfirmation = false
    
    private let bookingService = BookingService.shared
    private let gymsService = GymsService.shared
    
    let durationOptions = [30, 60, 90, 120, 180, 240]
    
    // MARK: - Computed Properties
    var totalPrice: Double {
        guard let gym = selectedGym else { return 0 }
        let hours = Double(selectedDuration) / 60.0
        return gym.pricePerHour * hours
    }
    
    var formattedDuration: String {
        let hours = selectedDuration / 60
        let minutes = selectedDuration % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Create Booking
    func createBooking() async {
        guard let gym = selectedGym else {
            errorMessage = "No gym selected"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let booking = try await bookingService.createBooking(
                gymId: gym.id,
                startTime: selectedDate,
                duration: selectedDuration
            )
            
            currentBooking = booking
            showConfirmation = true
            await loadBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Load Bookings
    func loadBookings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            bookings = try await bookingService.fetchBookings()
            categorizeBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func categorizeBookings() {
        let now = Date()
        
        upcomingBookings = bookings.filter {
            ($0.status == .confirmed || $0.status == .checkedIn) && $0.startTime > now
        }.sorted { $0.startTime < $1.startTime }
        
        pastBookings = bookings.filter {
            $0.status == .completed || $0.endTime < now
        }.sorted { $0.startTime > $1.startTime }
    }
    
    // MARK: - Load Availability
    func loadAvailability() async {
        guard let gym = selectedGym else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            availableSlots = try await gymsService.fetchAvailability(
                gymId: gym.id,
                date: selectedDate
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(_ booking: Booking) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await bookingService.cancelBooking(id: booking.id)
            await loadBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Booking Detail
    func fetchBookingDetail(_ bookingId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentBooking = try await bookingService.fetchBooking(id: bookingId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    func validateBooking() -> Bool {
        guard selectedGym != nil else {
            errorMessage = "Please select a gym"
            return false
        }
        
        guard selectedDate > Date() else {
            errorMessage = "Please select a future date and time"
            return false
        }
        
        guard selectedDuration >= AppConfig.Features.minBookingDuration else {
            errorMessage = "Minimum booking duration is \(AppConfig.Features.minBookingDuration) minutes"
            return false
        }
        
        guard selectedDuration <= AppConfig.Features.maxBookingDuration else {
            errorMessage = "Maximum booking duration is \(AppConfig.Features.maxBookingDuration) minutes"
            return false
        }
        
        return true
    }
}

