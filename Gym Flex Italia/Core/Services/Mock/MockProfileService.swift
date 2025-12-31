//
//  MockProfileService.swift
//  Gym Flex Italia
//
//  Mock implementation of ProfileServiceProtocol for testing and demo mode
//

import Foundation

/// Mock implementation of ProfileServiceProtocol
/// Returns realistic fake data with simulated network delays
final class MockProfileService: ProfileServiceProtocol {
    
    /// Stored profile for persistence during app session
    private var currentProfile: Profile = .mock
    
    // MARK: - ProfileServiceProtocol
    
    func fetchCurrentProfile() async throws -> Profile {
        // Simulate network delay (250-500ms)
        let delay = UInt64.random(in: 250_000_000...500_000_000)
        try await Task.sleep(nanoseconds: delay)
        
        return currentProfile
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        // Validate profile data
        try validateProfile(profile)
        
        // Check for test failure trigger
        if let fullName = profile.fullName, fullName.lowercased().contains("fail") {
            throw ProfileServiceError.updateFailed("Server error: Unable to save profile. Please try again later.")
        }
        
        // Simulate network delay (400-700ms)
        let delay = UInt64.random(in: 400_000_000...700_000_000)
        try await Task.sleep(nanoseconds: delay)
        
        // Update stored profile with new data and updated timestamp
        var updatedProfile = profile
        updatedProfile = Profile(
            id: profile.id,
            email: profile.email,
            fullName: profile.fullName,
            phoneNumber: profile.phoneNumber,
            avatarURL: profile.avatarURL,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            avatarLevel: profile.avatarLevel,
            totalWorkouts: profile.totalWorkouts,
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            avatarStyle: profile.avatarStyle,
            fitnessGoals: profile.fitnessGoals,
            preferredWorkoutTypes: profile.preferredWorkoutTypes,
            walletBalance: profile.walletBalance,
            createdAt: profile.createdAt,
            updatedAt: Date(), // Update timestamp
            lastWorkoutDate: profile.lastWorkoutDate
        )
        
        currentProfile = updatedProfile
        return updatedProfile
    }
    
    // MARK: - Validation
    
    private func validateProfile(_ profile: Profile) throws {
        // Validate full name
        if let fullName = profile.fullName {
            if fullName.trimmingCharacters(in: .whitespaces).count < 2 {
                throw ProfileServiceError.validationFailed("Name must be at least 2 characters long.")
            }
        }
        
        // Validate email
        if !profile.email.contains("@") || !profile.email.contains(".") {
            throw ProfileServiceError.validationFailed("Please enter a valid email address.")
        }
        
        // Validate phone (optional but if provided, should have minimum length)
        if let phone = profile.phoneNumber, !phone.isEmpty {
            let digitsOnly = phone.filter { $0.isNumber }
            if digitsOnly.count < 8 {
                throw ProfileServiceError.validationFailed("Phone number must have at least 8 digits.")
            }
        }
    }
}
