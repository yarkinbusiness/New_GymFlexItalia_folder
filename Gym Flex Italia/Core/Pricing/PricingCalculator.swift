//
//  PricingCalculator.swift
//  Gym Flex Italia
//
//  Centralized pricing logic for bookings.
//  Single source of truth for price calculations.
//

import Foundation

/// Centralized pricing calculator for consistent price calculations
struct PricingCalculator {
    
    // MARK: - Default Pricing (when gym-specific pricing is not available)
    
    /// Default price per hour in cents (€2.00)
    static let defaultPricePerHourCents: Int = 200
    
    // MARK: - Booking Price Calculation
    
    /// Calculate booking price from duration
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - pricePerHourCents: Price per hour in cents (defaults to €2.00)
    /// - Returns: Total price in cents
    static func priceForBooking(durationMinutes: Int, pricePerHourCents: Int = defaultPricePerHourCents) -> Int {
        let hours = Double(durationMinutes) / 60.0
        return Int(ceil(hours * Double(pricePerHourCents)))
    }
    
    /// Calculate booking price using gym's hourly rate
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - gymPricePerHour: Gym's price per hour in EUR (e.g., 3.50)
    /// - Returns: Total price in cents
    static func priceForBooking(durationMinutes: Int, gymPricePerHour: Double) -> Int {
        let pricePerHourCents = Int(gymPricePerHour * 100)
        return priceForBooking(durationMinutes: durationMinutes, pricePerHourCents: pricePerHourCents)
    }
    
    /// Calculate booking price and return as Double (for display)
    /// - Parameters:
    ///   - durationMinutes: Duration in minutes
    ///   - gymPricePerHour: Gym's price per hour in EUR
    /// - Returns: Total price in EUR
    static func priceForBookingEUR(durationMinutes: Int, gymPricePerHour: Double) -> Double {
        return Double(priceForBooking(durationMinutes: durationMinutes, gymPricePerHour: gymPricePerHour)) / 100.0
    }
    
    // MARK: - Formatting
    
    /// Format cents as EUR string (e.g., "€3.50")
    static func formatCentsAsEUR(_ cents: Int) -> String {
        let euros = Double(cents) / 100.0
        return String(format: "€%.2f", euros)
    }
    
    /// Format EUR amount (e.g., "€3.50")
    static func formatEUR(_ amount: Double) -> String {
        return String(format: "€%.2f", amount)
    }
}
