//
//  ProfileServiceProtocol.swift
//  Gym Flex Italia
//
//  Protocol defining profile-related operations
//

import Foundation

/// Errors that can occur during profile operations
enum ProfileServiceError: Error, LocalizedError {
    case fetchFailed(String)
    case updateFailed(String)
    case validationFailed(String)
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to load profile: \(message)"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .validationFailed(let message):
            return message
        case .networkError:
            return "Network connection error. Please check your internet."
        case .unauthorized:
            return "Session expired. Please log in again."
        }
    }
}

/// Protocol defining profile service operations
protocol ProfileServiceProtocol {
    /// Fetches the current user's profile
    func fetchCurrentProfile() async throws -> Profile
    
    /// Updates the user's profile with new data
    /// - Parameter profile: The updated profile data
    /// - Returns: The saved profile (may include server-side modifications)
    func updateProfile(_ profile: Profile) async throws -> Profile
    
    /// Records a workout for the user (avatar progression)
    /// - Parameter bookingId: The booking ID of the completed workout
    /// - Returns: Updated profile with any progression changes
    func recordWorkout(bookingId: String) async throws -> Profile
}
