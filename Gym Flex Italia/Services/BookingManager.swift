//
//  BookingManager.swift
//  Gym Flex Italia
//
//  Created by Antigravity on 11/23/25.
//

import Foundation
import SwiftUI
import Combine

/// Centralized booking state manager for app-wide booking synchronization
@MainActor
final class BookingManager: ObservableObject {
    
    static let shared = BookingManager()
    
    /// Current active booking (confirmed or checked-in)
    @Published var activeBooking: Booking?
    
    private init() {}
    
    /// Set the active booking and notify all observers
    func setActiveBooking(_ booking: Booking) {
        self.activeBooking = booking
        print("📋 BookingManager: Active booking set - \(booking.id)")
    }
    
    /// Clear the active booking
    func clearActiveBooking() {
        self.activeBooking = nil
        print("📋 BookingManager: Active booking cleared")
    }
    
    /// Check if there's an active booking
    var hasActiveBooking: Bool {
        activeBooking != nil
    }
}
