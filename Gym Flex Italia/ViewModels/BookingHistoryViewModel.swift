//
//  BookingHistoryViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for the booking history screen
//

import Foundation
import Combine

/// ViewModel for booking history with upcoming/past bookings and cancel functionality
@MainActor
final class BookingHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message (nil if no error)
    @Published var errorMessage: String?
    
    /// Success message (e.g., after cancellation)
    @Published var successMessage: String?
    
    /// All bookings
    @Published var bookings: [Booking] = []
    
    /// Whether a cancel operation is in progress
    @Published var isCancelling = false
    
    // MARK: - Computed Properties
    
    /// Upcoming bookings (confirmed and start time in future)
    var upcomingBookings: [Booking] {
        bookings.filter { $0.status == .confirmed && $0.startTime > Date() }
            .sorted { $0.startTime < $1.startTime }
    }
    
    /// Past bookings (completed, cancelled, or past start time)
    var pastBookings: [Booking] {
        bookings.filter { $0.status != .confirmed || $0.startTime <= Date() }
            .sorted { $0.startTime > $1.startTime }
    }
    
    /// Whether we have any bookings
    var hasBookings: Bool {
        !bookings.isEmpty
    }
    
    /// Whether we have upcoming bookings
    var hasUpcoming: Bool {
        !upcomingBookings.isEmpty
    }
    
    /// Whether we have past bookings
    var hasPast: Bool {
        !pastBookings.isEmpty
    }
    
    // MARK: - Public Methods
    
    /// Loads all bookings
    func load(using service: BookingHistoryServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            bookings = try await service.fetchBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Refreshes bookings without showing full loading state
    func refresh(using service: BookingHistoryServiceProtocol) async {
        errorMessage = nil
        
        do {
            bookings = try await service.fetchBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Cancels a booking by ID
    /// - Returns: true if cancellation was successful
    func cancel(id: String, using service: BookingHistoryServiceProtocol) async -> Bool {
        isCancelling = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let updatedBooking = try await service.cancelBooking(id: id)
            
            // Update the booking in our list
            if let index = bookings.firstIndex(where: { $0.id == id }) {
                bookings[index] = updatedBooking
            }
            
            successMessage = "Booking cancelled successfully. Refund will be processed within 3-5 business days."
            isCancelling = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isCancelling = false
            return false
        }
    }
    
    /// Gets a booking by ID
    func booking(for id: String) -> Booking? {
        bookings.first { $0.id == id }
    }
    
    /// Clears error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clears success message
    func clearSuccess() {
        successMessage = nil
    }
}

