//
//  BookingServiceProtocol.swift
//  Gym Flex Italia
//
//  Created for Mock Backend Layer
//

import Foundation

/// Protocol defining booking-related service operations
/// This abstraction allows swapping between Mock and Live implementations
protocol BookingServiceProtocol {
    /// Creates a new booking for a gym
    /// - Parameters:
    ///   - gymId: The gym's unique identifier
    ///   - date: The desired booking date/time
    ///   - duration: Duration in minutes (optional, defaults to 60)
    /// - Returns: BookingConfirmation with reference code
    /// - Throws: Error if booking fails
    func createBooking(gymId: String, date: Date, duration: Int) async throws -> BookingConfirmation
}

/// Errors that can occur during booking service operations
enum BookingServiceError: LocalizedError {
    case bookingFailed
    case invalidGym
    case slotUnavailable
    case insufficientFunds
    case activeSessionExists
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .bookingFailed:
            return "Failed to create booking"
        case .invalidGym:
            return "Invalid gym selected"
        case .slotUnavailable:
            return "This time slot is not available"
        case .insufficientFunds:
            return "Insufficient wallet balance. Please top up your wallet."
        case .activeSessionExists:
            return "You already have an active session. End or cancel it before booking another."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
