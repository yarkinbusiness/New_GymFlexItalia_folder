//
//  CheckInServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol defining check-in service operations
//

import Foundation

/// Result of a successful check-in operation
struct CheckInResult {
    /// The booking that was checked in
    let booking: Booking
    
    /// When the check-in occurred
    let checkedInAt: Date
    
    /// Success message for display
    let message: String
}

/// Protocol defining check-in service operations
protocol CheckInServiceProtocol {
    /// Validates a check-in code and marks the booking as checked in
    /// - Parameters:
    ///   - code: The check-in code (e.g., "CHK-ABC123")
    ///   - bookingId: The booking ID to check in
    /// - Returns: The result of the check-in operation
    func checkIn(code: String, bookingId: String) async throws -> CheckInResult
    
    /// Validates a check-in code format
    /// - Parameter code: The code to validate
    /// - Returns: true if the code format is valid
    func isValidCodeFormat(_ code: String) -> Bool
    
    /// Extends an active session
    /// - Parameters:
    ///   - bookingId: The booking to extend
    ///   - additionalMinutes: Minutes to add
    /// - Returns: Updated booking with extended time
    func extendSession(bookingId: String, additionalMinutes: Int) async throws -> Booking
    
    /// Checks out of an active session
    /// - Parameter bookingId: The booking to check out
    /// - Returns: Updated booking with completed status
    func checkOut(bookingId: String) async throws -> Booking
}

/// Errors that can occur during check-in operations
enum CheckInServiceError: LocalizedError {
    case invalidCodeFormat
    case bookingNotFound
    case codeMismatch
    case alreadyCheckedIn
    case bookingNotUpcoming
    case bookingCancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCodeFormat:
            return "Invalid check-in code format. Code should be CHK- followed by 6 characters."
        case .bookingNotFound:
            return "Booking not found. Please verify your booking details."
        case .codeMismatch:
            return "Check-in code does not match. Please verify and try again."
        case .alreadyCheckedIn:
            return "This booking has already been checked in."
        case .bookingNotUpcoming:
            return "This booking cannot be checked in. It may have expired or not started yet."
        case .bookingCancelled:
            return "This booking has been cancelled and cannot be checked in."
        case .unknown(let message):
            return message
        }
    }
}
