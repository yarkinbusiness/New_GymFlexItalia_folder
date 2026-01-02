//
//  SessionUsageReport.swift
//  Gym Flex Italia
//
//  Usage and billing report for gym owners.
//

import Foundation

/// Session usage report for billing and analytics.
///
/// **Usage and billing report.**
///
/// This structure captures the complete usage data for a gym session,
/// including timing and billing information. It will be:
/// - Displayed in the owner app's dashboard
/// - Sent to backend for billing reconciliation
/// - Used for analytics and reporting
///
/// **Billing Rules**:
/// - Charged per-minute based on gym's hourly rate
/// - Minimum charge: 15 minutes
/// - Extensions are added to `totalMinutesUsed`
/// - Refunds are tracked separately
struct SessionUsageReport: Codable, Identifiable {
    
    /// Unique identifier for the report
    var id: String { bookingId }
    
    // MARK: - Booking Reference
    
    /// Booking ID
    let bookingId: String
    
    /// Gym where session occurred
    let gymId: String
    
    /// User who used the session
    let userId: String
    
    /// Reference code for display
    let referenceCode: String
    
    // MARK: - Timing
    
    /// Original booking start time
    let bookingStartTime: Date
    
    /// Original booking end time
    let bookingEndTime: Date
    
    /// Actual check-in time
    let checkInTime: Date
    
    /// Actual check-out time (nil if still active)
    let checkOutTime: Date?
    
    // MARK: - Usage
    
    /// Total minutes actually used
    let totalMinutesUsed: Int
    
    /// Minutes from original booking
    let bookedMinutes: Int
    
    /// Additional minutes from extensions
    let extensionMinutes: Int
    
    // MARK: - Billing
    
    /// Total amount charged in cents
    let totalAmountCharged: Int
    
    /// Currency code
    let currency: String
    
    /// Gym's hourly rate at time of booking (in cents)
    let hourlyRateCents: Int
    
    /// Whether payment was completed
    let paymentCompleted: Bool
    
    // MARK: - Status
    
    /// Session status
    let status: SessionStatus
    
    /// How the session ended
    let endReason: EndReason?
    
    // MARK: - Nested Types
    
    enum SessionStatus: String, Codable {
        case active       // User is currently in gym
        case completed    // Normal checkout
        case expired      // Session ended due to time
        case cancelled    // Booking was cancelled
    }
    
    enum EndReason: String, Codable {
        case userCheckout     // User tapped checkout
        case autoExpire       // Session time ran out
        case ownerOverride    // Owner ended session
        case systemError      // Unexpected error
    }
    
    // MARK: - Computed Properties
    
    /// Whether session is currently active
    var isActive: Bool {
        status == .active && checkOutTime == nil
    }
    
    /// Formatted total amount
    var formattedAmount: String {
        let amount = Double(totalAmountCharged) / 100.0
        return String(format: "€%.2f", amount)
    }
    
    /// Duration as formatted string
    var formattedDuration: String {
        let hours = totalMinutesUsed / 60
        let minutes = totalMinutesUsed % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Factory

extension SessionUsageReport {
    
    /// Creates a usage report from a completed session
    static func create(
        booking: Booking,
        checkInTime: Date,
        checkOutTime: Date?,
        extensionMinutes: Int = 0,
        status: SessionStatus,
        endReason: EndReason? = nil
    ) -> SessionUsageReport {
        let gym = MockDataStore.shared.gymById(booking.gymId)
        let hourlyRateCents = Int((gym?.pricePerHour ?? 0) * 100)
        
        // Calculate booked minutes
        let bookedMinutes = Int(booking.endTime.timeIntervalSince(booking.startTime) / 60)
        
        // Calculate actual usage
        let actualEndTime = checkOutTime ?? Date()
        let actualMinutes = Int(actualEndTime.timeIntervalSince(checkInTime) / 60)
        let totalMinutes = max(15, actualMinutes) // Minimum 15 minute charge
        
        // Calculate charge (per-minute billing)
        let perMinuteRate = Double(hourlyRateCents) / 60.0
        let totalCharge = Int(Double(totalMinutes) * perMinuteRate)
        
        return SessionUsageReport(
            bookingId: booking.id,
            gymId: booking.gymId,
            userId: booking.userId,
            referenceCode: booking.checkinCode ?? "N/A",
            bookingStartTime: booking.startTime,
            bookingEndTime: booking.endTime,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            totalMinutesUsed: totalMinutes,
            bookedMinutes: bookedMinutes,
            extensionMinutes: extensionMinutes,
            totalAmountCharged: totalCharge,
            currency: "EUR",
            hourlyRateCents: hourlyRateCents,
            paymentCompleted: status == .completed || status == .expired,
            status: status,
            endReason: endReason
        )
    }
}
