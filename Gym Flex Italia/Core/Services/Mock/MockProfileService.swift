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
    
    func recordWorkout(bookingId: String) async throws -> Profile {
        // Simulate network delay (300-500ms)
        let delay = UInt64.random(in: 300_000_000...500_000_000)
        try await Task.sleep(nanoseconds: delay)
        
        // Increment workout count and potentially level
        let newTotalWorkouts = currentProfile.totalWorkouts + 1
        var newLevel = currentProfile.avatarLevel
        
        // Level up every 5 workouts
        if newTotalWorkouts % 5 == 0 {
            newLevel = min(newLevel + 1, 50) // Cap at level 50
        }
        
        currentProfile = Profile(
            id: currentProfile.id,
            email: currentProfile.email,
            fullName: currentProfile.fullName,
            phoneNumber: currentProfile.phoneNumber,
            avatarURL: currentProfile.avatarURL,
            dateOfBirth: currentProfile.dateOfBirth,
            gender: currentProfile.gender,
            avatarLevel: newLevel,
            totalWorkouts: newTotalWorkouts,
            currentStreak: currentProfile.currentStreak + 1,
            longestStreak: max(currentProfile.longestStreak, currentProfile.currentStreak + 1),
            avatarStyle: currentProfile.avatarStyle,
            fitnessGoals: currentProfile.fitnessGoals,
            preferredWorkoutTypes: currentProfile.preferredWorkoutTypes,
            walletBalance: currentProfile.walletBalance,
            createdAt: currentProfile.createdAt,
            updatedAt: Date(),
            lastWorkoutDate: Date()
        )
        
        return currentProfile
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
