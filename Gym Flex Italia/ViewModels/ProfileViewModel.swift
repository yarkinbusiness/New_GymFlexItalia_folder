//
//  ProfileViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import Combine

/// ViewModel for user profile management
@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var profile: Profile?
    @Published var stats: WorkoutStats?
    @Published var recentBookings: [Booking] = []
    @Published var selectedGoals: Set<FitnessGoal> = []
    @Published var selectedAvatarStyle: AvatarStyle = .warrior
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let profileService = ProfileService.shared
    private let bookingService = BookingService.shared
    private let authService = AuthService.shared
    
    init() {
        loadProfile()
    }
    
    // MARK: - Load Profile
    func loadProfile() {
        Task {
            await fetchProfile()
            await fetchStats()
            await fetchRecentBookings()
        }
    }
    
    private func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profile = try await profileService.fetchProfile()
            selectedGoals = Set(profile?.fitnessGoals ?? [])
            selectedAvatarStyle = profile?.avatarStyle ?? .warrior
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchStats() async {
        do {
            stats = try await profileService.fetchWorkoutStats()
        } catch {
            print("Failed to fetch stats: \(error)")
        }
    }
    
    private func fetchRecentBookings() async {
        do {
            let allBookings = try await bookingService.fetchBookings()
            recentBookings = allBookings
                .sorted { $0.startTime > $1.startTime }
                .prefix(10)
                .map { $0 }
        } catch {
            print("Failed to fetch bookings: \(error)")
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(fullName: String?, phoneNumber: String?, dateOfBirth: Date?, gender: Profile.Gender?) async {
        guard var updatedProfile = profile else { return }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        updatedProfile.fullName = fullName
        updatedProfile.phoneNumber = phoneNumber
        updatedProfile.dateOfBirth = dateOfBirth
        updatedProfile.gender = gender
        
        do {
            profile = try await profileService.updateProfile(updatedProfile)
            successMessage = "Profile updated successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    // MARK: - Update Goals
    func updateFitnessGoals() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            profile = try await profileService.updateFitnessGoals(Array(selectedGoals))
            successMessage = "Goals updated successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    func toggleGoal(_ goal: FitnessGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    // MARK: - Update Avatar
    func updateAvatarStyle() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        do {
            profile = try await profileService.updateAvatarStyle(selectedAvatarStyle)
            successMessage = "Avatar style updated"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    // MARK: - Avatar Progression
    var avatarProgression: AvatarProgression? {
        guard let profile = profile else { return nil }
        
        return AvatarProgression(
            currentLevel: profile.avatarLevel,
            totalWorkouts: profile.totalWorkouts,
            currentStreak: profile.currentStreak,
            style: profile.avatarStyle
        )
    }
    
    // MARK: - Statistics
    var totalWorkoutTime: String {
        guard let stats = stats else { return "0h" }
        let hours = stats.totalMinutes / 60
        let minutes = stats.totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var averageWorkoutsPerWeek: Double {
        guard let stats = stats else { return 0 }
        // Assuming weeklyWorkouts is for the current week
        return Double(stats.weeklyWorkouts)
    }
    
    // MARK: - Account Actions
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        authService.signOut()
    }
    
    // MARK: - Refresh
    func refresh() async {
        await fetchProfile()
        await fetchStats()
        await fetchRecentBookings()
    }
}

