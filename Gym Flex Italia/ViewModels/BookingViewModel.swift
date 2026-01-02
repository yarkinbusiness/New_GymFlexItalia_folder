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
    func createBooking(using service: BookingServiceProtocol) async {
        guard let gym = selectedGym else {
            errorMessage = "No gym selected"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let confirmation = try await service.createBooking(
                gymId: gym.id,
                date: selectedDate,
                duration: selectedDuration
            )
            
            // Create a mock booking from confirmation for display
            let endTime = confirmation.startTime.addingTimeInterval(TimeInterval(confirmation.duration * 60))
            currentBooking = Booking(
                id: confirmation.referenceCode,
                userId: "user_123",
                gymId: gym.id,
                gymName: gym.name,
                gymAddress: gym.address,
                gymCoverImageURL: gym.coverImageURL,
                startTime: confirmation.startTime,
                endTime: endTime,
                duration: confirmation.duration,
                pricePerHour: gym.pricePerHour,
                totalPrice: confirmation.totalPrice,
                currency: gym.currency,
                status: .confirmed,
                checkinCode: nil,
                checkinTime: nil,
                checkoutTime: nil,
                qrCodeData: nil,
                qrCodeExpiresAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                cancelledAt: nil,
                cancellationReason: nil
            )
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Load Bookings
    func loadBookings(using service: BookingHistoryServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            bookings = try await service.fetchBookings()
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
    func loadAvailability(using service: GymServiceProtocol) async {
        // Availability fetching not supported by current protocol
        // This would need to be added to GymServiceProtocol if needed
        availableSlots = []
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(_ booking: Booking, using service: BookingHistoryServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await service.cancelBooking(id: booking.id)
            await loadBookings(using: service)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Fetch Booking Detail
    func fetchBookingDetail(_ bookingId: String, using service: BookingHistoryServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentBooking = try await service.fetchBooking(id: bookingId)
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

