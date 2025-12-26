//
//  Booking.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Booking model for gym reservations
struct Booking: Codable, Identifiable {
    let id: String
    let userId: String
    let gymId: String
    
    // Gym info (denormalized for convenience)
    var gymName: String?
    var gymAddress: String?
    var gymCoverImageURL: String?
    
    // Booking Details
    var startTime: Date
    var endTime: Date
    var duration: Int // minutes
    
    // Pricing
    var pricePerHour: Double
    var totalPrice: Double
    var currency: String
    
    // Status & Check-in
    var status: BookingStatus
    var checkinCode: String?
    var checkinTime: Date?
    var checkoutTime: Date?
    
    // QR Code
    var qrCodeData: String?
    var qrCodeExpiresAt: Date?
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var cancelledAt: Date?
    var cancellationReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gymId = "gym_id"
        case gymName = "gym_name"
        case gymAddress = "gym_address"
        case gymCoverImageURL = "gym_cover_image_url"
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case pricePerHour = "price_per_hour"
        case totalPrice = "total_price"
        case currency
        case status
        case checkinCode = "checkin_code"
        case checkinTime = "checkin_time"
        case checkoutTime = "checkout_time"
        case qrCodeData = "qr_code_data"
        case qrCodeExpiresAt = "qr_code_expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cancelledAt = "cancelled_at"
        case cancellationReason = "cancellation_reason"
    }
    
    // Computed Properties
    var isUpcoming: Bool {
        status == .confirmed && startTime > Date()
    }
    
    var isActive: Bool {
        status == .checkedIn
    }
    
    var isPast: Bool {
        endTime < Date()
    }
    
    var canCheckIn: Bool {
        status == .confirmed && startTime <= Date() && endTime > Date()
    }
    
    var canCancel: Bool {
        status == .confirmed && startTime > Date()
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Booking Status
enum BookingStatus: String, Codable {
    case pending
    case confirmed
    case checkedIn = "checked_in"
    case completed
    case cancelled
    case noShow = "no_show"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .checkedIn: return "Checked In"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .checkedIn: return "person.crop.circle.fill.badge.checkmark"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .checkedIn: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .noShow: return "red"
        }
    }
}

