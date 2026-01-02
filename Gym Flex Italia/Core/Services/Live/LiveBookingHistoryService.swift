//
//  LiveBookingHistoryService.swift
//  Gym Flex Italia
//
//  Live implementation of BookingHistoryServiceProtocol using NetworkClient.
//  Scaffold only - endpoints not yet configured.
//

import Foundation

/// Live implementation of BookingHistoryServiceProtocol
/// Uses NetworkClient for real API calls.
/// Currently a scaffold - endpoints will be configured when backend is ready.
final class LiveBookingHistoryService: BookingHistoryServiceProtocol {
    
    // MARK: - Properties
    
    private let networkClient: NetworkClient
    
    // MARK: - Initialization
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - BookingHistoryServiceProtocol
    
    func fetchBookings() async throws -> [Booking] {
        // Endpoint: GET /v1/bookings
        let endpoint = APIEndpoint.get("/v1/bookings")
        return try await networkClient.send(endpoint, response: [Booking].self)
    }
    
    func fetchBooking(id: String) async throws -> Booking {
        // Endpoint: GET /v1/bookings/{id}
        let endpoint = APIEndpoint.get("/v1/bookings/\(id)")
        return try await networkClient.send(endpoint, response: Booking.self)
    }
    
    func cancelBooking(id: String) async throws -> Booking {
        // Endpoint: DELETE /v1/bookings/{id}
        // Returns the cancelled booking
        let endpoint = APIEndpoint.delete("/v1/bookings/\(id)")
        return try await networkClient.send(endpoint, response: Booking.self)
    }
}
