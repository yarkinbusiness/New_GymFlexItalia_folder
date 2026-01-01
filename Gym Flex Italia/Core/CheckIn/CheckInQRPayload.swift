//
//  CheckInQRPayload.swift
//  Gym Flex Italia
//
//  QR payload model for gym check-in.
//  Encodes booking info in a structured format for gym-owner scanning apps.
//

import Foundation

/// Structured payload for QR code check-in.
/// Designed to be encoded as base64 JSON within a URL scheme.
struct CheckInQRPayload: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Payload version for future compatibility
    let v: String
    
    /// Unique booking identifier
    let bookingId: String
    
    /// Human-readable booking reference (e.g., "GF-ABC123")
    let bookingRef: String
    
    /// Check-in code for manual entry (e.g., "CHK-XYZ789")
    let checkInCode: String
    
    /// Gym identifier
    let gymId: String
    
    /// User identifier
    let userId: String
    
    /// Start time in ISO 8601 format
    let startAtISO: String
    
    /// Duration in minutes
    let durationMin: Int
    
    /// Amount in cents (optional, for spend tracking)
    let amountCents: Int?
    
    /// Currency code (e.g., "EUR")
    let currency: String
    
    /// When this payload was issued (ISO 8601)
    let issuedAtISO: String
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case v
        case bookingId = "booking_id"
        case bookingRef = "booking_ref"
        case checkInCode = "checkin_code"
        case gymId = "gym_id"
        case userId = "user_id"
        case startAtISO = "start_at"
        case durationMin = "duration_min"
        case amountCents = "amount_cents"
        case currency
        case issuedAtISO = "issued_at"
    }
    
    // MARK: - Factory Method
    
    /// Creates a QR payload from a booking
    /// - Parameter booking: The booking to create a payload for
    /// - Returns: A structured QR payload
    static func make(from booking: Booking) -> CheckInQRPayload {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Calculate amount in cents from totalPrice
        let amountCents = Int(booking.totalPrice * 100)
        
        return CheckInQRPayload(
            v: "1",
            bookingId: booking.id,
            bookingRef: booking.qrCodeData ?? booking.id, // Use qrCodeData as bookingRef if available
            checkInCode: booking.checkinCode ?? "CHK-UNKNOWN",
            gymId: booking.gymId,
            userId: booking.userId,
            startAtISO: isoFormatter.string(from: booking.startTime),
            durationMin: booking.duration,
            amountCents: amountCents,
            currency: booking.currency,
            issuedAtISO: isoFormatter.string(from: Date())
        )
    }
    
    // MARK: - Encoding
    
    /// Converts the payload to a base64-encoded JSON string
    /// - Returns: Base64 string representation of the JSON payload
    func toBase64JSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys // Consistent output
        
        do {
            let jsonData = try encoder.encode(self)
            return jsonData.base64EncodedString()
        } catch {
            // Fallback: return empty string (shouldn't happen with valid data)
            return ""
        }
    }
    
    /// Creates the full QR code content URL
    /// Format: gymflex://checkin?payload=<base64>
    /// - Returns: The complete URL string for QR encoding
    func toQRCodeString() -> String {
        let base64Payload = toBase64JSONString()
        return "gymflex://checkin?payload=\(base64Payload)"
    }
    
    // MARK: - Decoding (for future gym-owner app)
    
    /// Attempts to decode a payload from a QR code string
    /// - Parameter qrCodeString: The QR code content (gymflex://checkin?payload=...)
    /// - Returns: Decoded payload if successful, nil otherwise
    static func decode(from qrCodeString: String) -> CheckInQRPayload? {
        // Parse the URL
        guard let url = URL(string: qrCodeString),
              url.scheme == "gymflex",
              url.host == "checkin",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payloadItem = components.queryItems?.first(where: { $0.name == "payload" }),
              let base64String = payloadItem.value,
              let jsonData = Data(base64Encoded: base64String) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(CheckInQRPayload.self, from: jsonData)
    }
}
