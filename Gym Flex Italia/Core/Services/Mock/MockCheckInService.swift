//
//  MockCheckInService.swift
//  Gym Flex Italia
//
//  Mock implementation of CheckInServiceProtocol for demo/testing.
//  Uses MockBookingStore as the single source of truth.
//

import Foundation

/// Mock check-in service that validates codes against MockBookingStore
final class MockCheckInService: CheckInServiceProtocol {
    
    // MARK: - CheckInServiceProtocol
    
    func checkIn(code: String, bookingId: String) async throws -> CheckInResult {
        // Simulate network delay (300-700ms)
        try await simulateNetworkDelay()
        
        // Deterministic failure for testing: code contains "FAIL"
        if code.uppercased().contains("FAIL") {
            throw CheckInServiceError.unknown("Simulated scanner failure. Please try again.")
        }
        
        // Validate code format
        guard isValidCodeFormat(code) else {
            throw CheckInServiceError.invalidCodeFormat
        }
        
        // Find the booking in the store
        guard let booking = MockBookingStore.shared.bookingById(bookingId) else {
            throw CheckInServiceError.bookingNotFound
        }
        
        // Check if cancelled
        if booking.status == .cancelled {
            throw CheckInServiceError.bookingCancelled
        }
        
        // Check if already checked in
        if booking.checkinTime != nil || booking.status == .checkedIn {
            throw CheckInServiceError.alreadyCheckedIn
        }
        
        // Verify status is upcoming/confirmed
        guard booking.status == .confirmed else {
            throw CheckInServiceError.bookingNotUpcoming
        }
        
        // Validate the check-in code matches
        guard let expectedCode = booking.checkinCode,
              code.uppercased() == expectedCode.uppercased() else {
            throw CheckInServiceError.codeMismatch
        }
        
        // Mark as checked in
        let checkedInAt = Date()
        guard let updatedBooking = MockBookingStore.shared.markCheckedIn(
            bookingId: bookingId,
            checkedInAt: checkedInAt
        ) else {
            throw CheckInServiceError.unknown("Failed to update booking status.")
        }
        
        return CheckInResult(
            booking: updatedBooking,
            checkedInAt: checkedInAt,
            message: "Successfully checked in! Enjoy your workout at \(booking.gymName ?? "the gym")."
        )
    }
    
    func isValidCodeFormat(_ code: String) -> Bool {
        // Format: CHK-XXXXXX (CHK- followed by 6 alphanumeric characters)
        let pattern = "^CHK-[A-Z0-9]{6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(code.startIndex..., in: code)
        return regex?.firstMatch(in: code, options: [], range: range) != nil
    }
    
    // MARK: - Helpers
    
    /// Simulates network delay (300-700ms)
    private func simulateNetworkDelay() async throws {
        let delayMs = Int.random(in: 300...700)
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }
}
