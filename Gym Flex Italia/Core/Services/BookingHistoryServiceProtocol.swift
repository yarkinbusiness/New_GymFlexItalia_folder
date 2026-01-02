//
//  BookingHistoryServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol for fetching and managing booking history
//

import Foundation

/// Protocol defining booking history service operations
protocol BookingHistoryServiceProtocol {
    /// Fetches all bookings for the current user
    func fetchBookings() async throws -> [Booking]
    
    /// Fetches a single booking by ID
    /// - Parameter id: The booking ID
    /// - Returns: The booking with the given ID
    func fetchBooking(id: String) async throws -> Booking
    
    /// Cancels a booking by ID
    /// - Parameter id: The booking ID to cancel
    /// - Returns: The updated booking with cancelled status
    func cancelBooking(id: String) async throws -> Booking
}

/// Errors that can occur during booking history operations
enum BookingHistoryServiceError: LocalizedError {
    case fetchFailed(String)
    case cancelFailed(String)
    case bookingNotFound
    case cannotCancelNonUpcoming
    case alreadyCancelled
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to load bookings: \(message)"
        case .cancelFailed(let message):
            return "Failed to cancel booking: \(message)"
        case .bookingNotFound:
            return "Booking not found"
        case .cannotCancelNonUpcoming:
            return "Only upcoming bookings can be cancelled"
        case .alreadyCancelled:
            return "This booking has already been cancelled"
        }
    }
}

