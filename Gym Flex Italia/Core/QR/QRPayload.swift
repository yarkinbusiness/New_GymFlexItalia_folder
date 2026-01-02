//
//  QRPayload.swift
//  Gym Flex Italia
//
//  Contract between user app and gym owner app for QR code scanning.
//  The QR code encodes this structure as JSON.
//

import Foundation
import CryptoKit

/// QR code payload structure.
///
/// **Contract between user app and gym owner app.**
///
/// This is the data encoded in the user's QR code that gym owners scan
/// to validate check-ins. The owner app decodes this JSON, verifies the
/// checksum, and validates the session timing.
///
/// **Security**:
/// - `checksum` is a SHA256 hash of all other fields
/// - Prevents tampering with booking/session data
/// - Owner app must verify checksum before accepting
///
/// **Usage**:
/// ```swift
/// // Generate QR payload from booking
/// let payload = QRPayload.generate(from: booking)
///
/// // Encode as JSON string for QR code
/// let qrString = payload.toQRString()
///
/// // Decode from scanned QR (owner app)
/// let decoded = QRPayload.from(qrString: scannedString)
/// ```
struct QRPayload: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Unique booking identifier
    let bookingId: String
    
    /// Gym where the session is valid
    let gymId: String
    
    /// User who made the booking
    let userId: String
    
    /// Session start time
    let sessionStart: Date
    
    /// Session end time
    let sessionEnd: Date
    
    /// Human-readable reference code (e.g., "CHK-ABC123")
    let referenceCode: String
    
    /// SHA256 checksum of all other fields (hex string)
    /// Used to verify payload integrity
    let checksum: String
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case bookingId = "bid"
        case gymId = "gid"
        case userId = "uid"
        case sessionStart = "start"
        case sessionEnd = "end"
        case referenceCode = "ref"
        case checksum = "cs"
    }
    
    // MARK: - Generation
    
    /// Generates a QRPayload from booking data
    /// - Parameters:
    ///   - bookingId: The booking ID
    ///   - gymId: The gym ID
    ///   - userId: The user ID
    ///   - sessionStart: Session start time
    ///   - sessionEnd: Session end time
    ///   - referenceCode: Human-readable reference
    /// - Returns: A complete QRPayload with computed checksum
    static func generate(
        bookingId: String,
        gymId: String,
        userId: String,
        sessionStart: Date,
        sessionEnd: Date,
        referenceCode: String
    ) -> QRPayload {
        let checksum = computeChecksum(
            bookingId: bookingId,
            gymId: gymId,
            userId: userId,
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            referenceCode: referenceCode
        )
        
        return QRPayload(
            bookingId: bookingId,
            gymId: gymId,
            userId: userId,
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            referenceCode: referenceCode,
            checksum: checksum
        )
    }
    
    /// Generates a QRPayload from a Booking model
    static func generate(from booking: Booking) -> QRPayload {
        return generate(
            bookingId: booking.id,
            gymId: booking.gymId,
            userId: booking.userId,
            sessionStart: booking.startTime,
            sessionEnd: booking.endTime,
            referenceCode: booking.checkinCode ?? MockDataStore.makeCheckinCode()
        )
    }
    
    // MARK: - Checksum
    
    /// Computes SHA256 checksum of payload fields
    private static func computeChecksum(
        bookingId: String,
        gymId: String,
        userId: String,
        sessionStart: Date,
        sessionEnd: Date,
        referenceCode: String
    ) -> String {
        // Create deterministic string from all fields
        let startTimestamp = Int(sessionStart.timeIntervalSince1970)
        let endTimestamp = Int(sessionEnd.timeIntervalSince1970)
        
        let dataString = "\(bookingId)|\(gymId)|\(userId)|\(startTimestamp)|\(endTimestamp)|\(referenceCode)"
        
        // Compute SHA256
        let data = Data(dataString.utf8)
        let hash = SHA256.hash(data: data)
        
        // Convert to hex string (first 16 chars for brevity)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).lowercased()
    }
    
    /// Verifies that the checksum matches the computed value
    var isChecksumValid: Bool {
        let computed = QRPayload.computeChecksum(
            bookingId: bookingId,
            gymId: gymId,
            userId: userId,
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            referenceCode: referenceCode
        )
        
        let isValid = computed == checksum
        
        #if DEBUG
        if !isValid {
            print("⚠️ QRPayload checksum mismatch: expected '\(computed)', got '\(checksum)'")
        }
        #endif
        
        return isValid
    }
    
    // MARK: - Serialization
    
    /// Encodes payload as JSON string for QR code
    func toQRString() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Decodes payload from QR code JSON string
    static func from(qrString: String) -> QRPayload? {
        guard let data = qrString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try? decoder.decode(QRPayload.self, from: data)
    }
    
    // MARK: - Validation Helpers
    
    /// Checks if the session is currently valid (within time window)
    var isWithinSessionWindow: Bool {
        let now = Date()
        return now >= sessionStart && now <= sessionEnd
    }
    
    /// Checks if the session has expired
    var isExpired: Bool {
        Date() > sessionEnd
    }
    
    /// Checks if the session hasn't started yet
    var isNotStarted: Bool {
        Date() < sessionStart
    }
    
    /// Remaining minutes in the session (0 if expired)
    var remainingMinutes: Int {
        guard !isExpired else { return 0 }
        let remaining = sessionEnd.timeIntervalSinceNow
        return max(0, Int(remaining / 60))
    }
}
