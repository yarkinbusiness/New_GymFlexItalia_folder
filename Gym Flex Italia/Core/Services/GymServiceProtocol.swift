//
//  GymServiceProtocol.swift
//  Gym Flex Italia
//
//  Created for Mock Backend Layer
//

import Foundation

/// Protocol defining gym-related service operations
/// This abstraction allows swapping between Mock and Live implementations
protocol GymServiceProtocol {
    /// Fetches all available gyms
    /// - Returns: Array of Gym objects
    /// - Throws: Error if fetch fails
    func fetchGyms() async throws -> [Gym]
    
    /// Fetches details for a specific gym
    /// - Parameter id: The gym's unique identifier
    /// - Returns: The Gym object with full details
    /// - Throws: Error if gym not found or fetch fails
    func fetchGymDetail(id: String) async throws -> Gym
}

/// Errors that can occur during gym service operations
enum GymServiceError: LocalizedError {
    case gymNotFound
    case fetchFailed
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .gymNotFound:
            return "Gym not found"
        case .fetchFailed:
            return "Failed to fetch gym data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
