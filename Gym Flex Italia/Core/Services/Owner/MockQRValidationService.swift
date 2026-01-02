//
//  MockQRValidationService.swift
//  Gym Flex Italia
//
//  Mock validation service for owner app QR scanning.
//

import Foundation

/// Protocol for QR code validation (owner app)
protocol QRValidationServiceProtocol {
    /// Validates a QR code string
    /// - Parameters:
    ///   - qrString: The scanned QR code content
    ///   - validatorGymId: The gym ID of the validator (owner's gym)
    /// - Returns: Validation result
    func validate(qrString: String, validatorGymId: String) async -> QRValidationResult
    
    /// Validates a pre-decoded payload
    func validate(payload: QRPayload, validatorGymId: String) async -> QRValidationResult
}

/// Mock implementation of QR validation service
///
/// Used by the gym owner app to validate user QR codes.
/// In production, this would be replaced with a backend call.
///
/// **Validation Steps**:
/// 1. Decode QR string to QRPayload
/// 2. Verify checksum integrity
/// 3. Check gym ID matches validator's gym
/// 4. Verify session timing (not expired, not too early)
/// 5. Check booking status (not cancelled)
///
/// **No Network Calls**: This is fully local/mock for now.
final class MockQRValidationService: QRValidationServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = MockQRValidationService()
    
    private init() {}
    
    // MARK: - QRValidationServiceProtocol
    
    func validate(qrString: String, validatorGymId: String) async -> QRValidationResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Step 1: Decode QR string
        guard let payload = QRPayload.from(qrString: qrString) else {
            return .invalid(reason: "Could not decode QR code")
        }
        
        return await validate(payload: payload, validatorGymId: validatorGymId)
    }
    
    func validate(payload: QRPayload, validatorGymId: String) async -> QRValidationResult {
        // Step 2: Verify checksum
        guard payload.isChecksumValid else {
            #if DEBUG
            assertionFailure("QR checksum mismatch - possible tampering detected")
            #endif
            return .invalid(reason: "Checksum verification failed")
        }
        
        // Step 3: Check gym ID matches
        guard payload.gymId == validatorGymId else {
            return .wrongGym(payload: payload, expectedGymId: validatorGymId)
        }
        
        // Step 4: Check booking status (from mock store)
        if let booking = MockBookingStore.shared.bookingById(payload.bookingId) {
            if booking.status == .cancelled {
                return .cancelled(payload: payload)
            }
            
            if booking.status == .checkedIn {
                return .alreadyCheckedIn(payload: payload)
            }
        }
        
        // Step 5: Check timing
        if payload.isNotStarted {
            return .notStarted(payload: payload)
        }
        
        if payload.isExpired {
            return .expired(payload: payload)
        }
        
        // All checks passed
        return .valid(payload: payload, remainingMinutes: payload.remainingMinutes)
    }
    
    // MARK: - Helper Methods
    
    /// Generates a QR payload for a booking
    /// - Parameter booking: The booking to generate QR for
    /// - Returns: QRPayload, or nil if generation fails
    func generatePayload(for booking: Booking) -> QRPayload {
        QRPayload.generate(from: booking)
    }
    
    /// Generates QR code content string for a booking
    /// - Parameter booking: The booking to generate QR for
    /// - Returns: JSON string suitable for QR code encoding
    func generateQRString(for booking: Booking) -> String? {
        let payload = generatePayload(for: booking)
        return payload.toQRString()
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension MockQRValidationService {
    /// Creates a test payload that will validate successfully
    func createTestValidPayload(gymId: String) -> QRPayload {
        QRPayload.generate(
            bookingId: "test_booking_\(UUID().uuidString.prefix(8))",
            gymId: gymId,
            userId: MockDataStore.mockUserId,
            sessionStart: Date().addingTimeInterval(-300), // Started 5 min ago
            sessionEnd: Date().addingTimeInterval(3300),   // Ends in 55 min
            referenceCode: MockDataStore.makeCheckinCode()
        )
    }
    
    /// Creates a test payload that will be expired
    func createTestExpiredPayload(gymId: String) -> QRPayload {
        QRPayload.generate(
            bookingId: "test_expired_\(UUID().uuidString.prefix(8))",
            gymId: gymId,
            userId: MockDataStore.mockUserId,
            sessionStart: Date().addingTimeInterval(-7200), // Started 2h ago
            sessionEnd: Date().addingTimeInterval(-3600),   // Ended 1h ago
            referenceCode: MockDataStore.makeCheckinCode()
        )
    }
    
    /// Creates a test payload for wrong gym
    func createTestWrongGymPayload(wrongGymId: String) -> QRPayload {
        QRPayload.generate(
            bookingId: "test_wronggym_\(UUID().uuidString.prefix(8))",
            gymId: wrongGymId,
            userId: MockDataStore.mockUserId,
            sessionStart: Date().addingTimeInterval(-300),
            sessionEnd: Date().addingTimeInterval(3300),
            referenceCode: MockDataStore.makeCheckinCode()
        )
    }
}
#endif
