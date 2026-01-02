//
//  QRValidationResult.swift
//  Gym Flex Italia
//
//  Owner app validation response contract.
//

import Foundation

/// Status of QR code validation
///
/// **Owner app validation response.**
///
/// When a gym owner scans a user's QR code, this status indicates
/// whether the check-in is allowed.
enum QRValidationStatus: String, Codable {
    /// QR code is valid - allow check-in
    case valid
    
    /// Session has expired - deny check-in
    case expired
    
    /// QR code is invalid (bad format, bad checksum, etc.)
    case invalid
    
    /// QR code is for a different gym
    case wrongGym
    
    /// Session hasn't started yet
    case notStarted
    
    /// User is already checked in
    case alreadyCheckedIn
    
    /// Booking was cancelled
    case cancelled
}

/// Result of QR code validation by owner app
///
/// **Owner app validation response.**
///
/// Contains the validation status along with relevant booking details
/// that the owner app can display.
struct QRValidationResult: Codable {
    
    /// Validation status
    let status: QRValidationStatus
    
    /// Booking ID (if decoded successfully)
    let bookingId: String?
    
    /// Gym ID from the QR code
    let gymId: String?
    
    /// User ID from the QR code
    let userId: String?
    
    /// Reference code for display
    let referenceCode: String?
    
    /// Remaining minutes in session (if valid)
    let remainingMinutes: Int?
    
    /// Human-readable message for owner display
    let message: String
    
    /// Session start time (if decoded)
    let sessionStart: Date?
    
    /// Session end time (if decoded)
    let sessionEnd: Date?
    
    // MARK: - Factory Methods
    
    /// Creates a valid result
    static func valid(
        payload: QRPayload,
        remainingMinutes: Int
    ) -> QRValidationResult {
        QRValidationResult(
            status: .valid,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: remainingMinutes,
            message: "✅ Valid check-in. \(remainingMinutes) minutes remaining.",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
    
    /// Creates an expired result
    static func expired(payload: QRPayload) -> QRValidationResult {
        QRValidationResult(
            status: .expired,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: 0,
            message: "⏰ Session has expired.",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
    
    /// Creates a not-started result
    static func notStarted(payload: QRPayload) -> QRValidationResult {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        return QRValidationResult(
            status: .notStarted,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: nil,
            message: "⏳ Session starts at \(formatter.string(from: payload.sessionStart)).",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
    
    /// Creates a wrong-gym result
    static func wrongGym(payload: QRPayload, expectedGymId: String) -> QRValidationResult {
        QRValidationResult(
            status: .wrongGym,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: nil,
            message: "🏢 This booking is for a different gym.",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
    
    /// Creates an invalid result
    static func invalid(reason: String) -> QRValidationResult {
        QRValidationResult(
            status: .invalid,
            bookingId: nil,
            gymId: nil,
            userId: nil,
            referenceCode: nil,
            remainingMinutes: nil,
            message: "❌ Invalid QR code: \(reason)",
            sessionStart: nil,
            sessionEnd: nil
        )
    }
    
    /// Creates an already-checked-in result
    static func alreadyCheckedIn(payload: QRPayload) -> QRValidationResult {
        QRValidationResult(
            status: .alreadyCheckedIn,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: payload.remainingMinutes,
            message: "ℹ️ User is already checked in.",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
    
    /// Creates a cancelled result
    static func cancelled(payload: QRPayload) -> QRValidationResult {
        QRValidationResult(
            status: .cancelled,
            bookingId: payload.bookingId,
            gymId: payload.gymId,
            userId: payload.userId,
            referenceCode: payload.referenceCode,
            remainingMinutes: nil,
            message: "🚫 This booking was cancelled.",
            sessionStart: payload.sessionStart,
            sessionEnd: payload.sessionEnd
        )
    }
}

// MARK: - Convenience

extension QRValidationResult {
    /// Whether the check-in should be allowed
    var isAllowed: Bool {
        status == .valid || status == .alreadyCheckedIn
    }
    
    /// Color indicator for status (for UI)
    var statusColor: String {
        switch status {
        case .valid:
            return "green"
        case .alreadyCheckedIn:
            return "blue"
        case .expired, .notStarted:
            return "orange"
        case .invalid, .wrongGym, .cancelled:
            return "red"
        }
    }
}
