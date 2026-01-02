//
//  MockBookingHistoryService.swift
//  Gym Flex Italia
//
//  Mock implementation of BookingHistoryServiceProtocol for demo/testing
//  Uses MockBookingStore as the single source of truth for bookings.
//

import Foundation

/// Mock booking history service that uses MockBookingStore for consistent state
/// All gym references come from MockDataStore for consistency
final class MockBookingHistoryService: BookingHistoryServiceProtocol {
    
    // MARK: - Initialization
    
    init() {
        // Ensure the store is seeded with initial data
        MockBookingStore.shared.seedIfNeeded()
    }
    
    // MARK: - BookingHistoryServiceProtocol
    
    func fetchBookings() async throws -> [Booking] {
        try await simulateNetworkDelay()
        return MockBookingStore.shared.allBookings()
    }
    
    func fetchBooking(id: String) async throws -> Booking {
        try await simulateNetworkDelay()
        guard let booking = MockBookingStore.shared.bookingById(id) else {
            throw BookingHistoryServiceError.bookingNotFound
        }
        return booking
    }
    
    func cancelBooking(id: String) async throws -> Booking {
        try await simulateNetworkDelay()
        
        // Deterministic failure for testing: if id contains "fail"
        if id.lowercased().contains("fail") {
            throw BookingHistoryServiceError.cancelFailed("Payment refund failed. Please try again or contact support.")
        }
        
        // Find the booking
        guard let booking = MockBookingStore.shared.bookingById(id) else {
            throw BookingHistoryServiceError.bookingNotFound
        }
        
        // Check if already cancelled
        if booking.status == .cancelled {
            throw BookingHistoryServiceError.alreadyCancelled
        }
        
        // Only upcoming/confirmed bookings can be cancelled
        guard booking.status == .confirmed && booking.startTime > Date() else {
            throw BookingHistoryServiceError.cannotCancelNonUpcoming
        }
        
        // Cancel the booking in the store
        guard let updatedBooking = MockBookingStore.shared.cancel(bookingId: id) else {
            throw BookingHistoryServiceError.cancelFailed("Failed to update booking status.")
        }
        
        return updatedBooking
    }
    
    // MARK: - Helpers
    
    /// Simulates network delay (300-700ms)
    private func simulateNetworkDelay() async throws {
        let delayMs = Int.random(in: 300...700)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }
}

