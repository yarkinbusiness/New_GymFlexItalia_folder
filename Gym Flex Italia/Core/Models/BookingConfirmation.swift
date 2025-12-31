//
//  BookingConfirmation.swift
//  Gym Flex Italia
//
//  Created for Mock Backend Layer
//

import Foundation

/// Represents a confirmed booking with reference code
/// This is returned after successfully creating a booking
struct BookingConfirmation: Codable, Equatable, Identifiable {
    /// Unique identifier for this confirmation (same as bookingId)
    var id: String { bookingId }
    
    /// The booking's unique identifier
    let bookingId: String
    
    /// The gym ID this booking is for
    let gymId: String
    
    /// Name of the gym (for display purposes)
    let gymName: String?
    
    /// When the booking was created
    let createdAt: Date
    
    /// Human-readable reference code (e.g., "GF-ABC123")
    let referenceCode: String
    
    /// Booking start time
    let startTime: Date
    
    /// Duration in minutes
    let duration: Int
    
    /// Total price for the booking
    let totalPrice: Double
    
    /// Currency code (e.g., "EUR")
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case gymId = "gym_id"
        case gymName = "gym_name"
        case createdAt = "created_at"
        case referenceCode = "reference_code"
        case startTime = "start_time"
        case duration
        case totalPrice = "total_price"
        case currency
    }
}
