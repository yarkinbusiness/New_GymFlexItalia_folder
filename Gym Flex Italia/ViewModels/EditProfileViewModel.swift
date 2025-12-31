//
//  EditProfileViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for editing user profile
//

import Foundation
import Combine

/// ViewModel for the Edit Profile screen
@MainActor
final class EditProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Loading state for async operations
    @Published var isLoading = false
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    
    /// Success message after saving (nil if not yet saved)
    @Published var successMessage: String?
    
    /// The profile being edited
    @Published var profile: Profile
    
    /// Individual editable fields (bound to form controls)
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var city: String = ""
    @Published var selectedGoal: FitnessGoal = .generalFitness
    @Published var heightCm: String = ""
    @Published var weightKg: String = ""
    
    // MARK: - Initialization
    
    init() {
        // Start with mock profile as placeholder
        self.profile = .mock
        syncFieldsFromProfile()
    }
    
    // MARK: - Public Methods
    
    /// Loads the current profile from the service
    func load(using service: ProfileServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            profile = try await service.fetchCurrentProfile()
            syncFieldsFromProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Saves the edited profile to the service
    func save(using service: ProfileServiceProtocol) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Sync fields back to profile
        syncFieldsToProfile()
        
        do {
            let savedProfile = try await service.updateProfile(profile)
            profile = savedProfile
            successMessage = "Profile updated successfully!"
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clears the success message
    func clearSuccess() {
        successMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Syncs individual fields from the profile object
    private func syncFieldsFromProfile() {
        fullName = profile.fullName ?? ""
        email = profile.email
        phone = profile.phoneNumber ?? ""
        city = "" // Profile doesn't have city, but we support it in UI
        
        // Set first fitness goal if available
        if let firstGoal = profile.fitnessGoals.first {
            selectedGoal = firstGoal
        }
        
        // Height and weight would come from profile if available
        // For now, leave empty as Profile model doesn't have these
        heightCm = ""
        weightKg = ""
    }
    
    /// Syncs individual fields back to the profile object
    private func syncFieldsToProfile() {
        profile = Profile(
            id: profile.id,
            email: email,
            fullName: fullName.isEmpty ? nil : fullName,
            phoneNumber: phone.isEmpty ? nil : phone,
            avatarURL: profile.avatarURL,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            avatarLevel: profile.avatarLevel,
            totalWorkouts: profile.totalWorkouts,
            currentStreak: profile.currentStreak,
            longestStreak: profile.longestStreak,
            avatarStyle: profile.avatarStyle,
            fitnessGoals: [selectedGoal],
            preferredWorkoutTypes: profile.preferredWorkoutTypes,
            walletBalance: profile.walletBalance,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            lastWorkoutDate: profile.lastWorkoutDate
        )
    }
}
