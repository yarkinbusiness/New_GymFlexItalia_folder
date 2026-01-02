//
//  AvailabilitySlot.swift
//  Gym Flex Italia
//
//  Model for gym time slot availability
//

import Foundation

/// Represents an availability slot for a gym
struct AvailabilitySlot: Codable, Identifiable, Equatable {
    /// Unique identifier for this slot
    let id: String
    
    /// The gym this slot belongs to
    let gymId: String
    
    /// Start time of the slot
    let startTime: Date
    
    /// End time of the slot
    let endTime: Date
    
    /// Whether this slot is available for booking
    let isAvailable: Bool
    
    /// Number of slots already booked
    let bookedSlots: Int
    
    /// Maximum capacity for this time slot
    let maxCapacity: Int
    
    /// Remaining available slots
    var remainingSlots: Int {
        max(0, maxCapacity - bookedSlots)
    }
    
    /// Whether the slot is nearly full (< 20% remaining)
    var isNearlyFull: Bool {
        Double(remainingSlots) / Double(maxCapacity) < 0.2
    }
}
