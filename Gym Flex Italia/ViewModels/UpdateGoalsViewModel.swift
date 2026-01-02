//
//  UpdateGoalsViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for updating fitness goals.
//

import Foundation
import Combine

/// ViewModel for fitness goals editing
@MainActor
final class UpdateGoalsViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var profile: Profile?
    @Published var selectedGoals: Set<FitnessGoal> = []
    
    // MARK: - Load
    
    func load(using service: ProfileServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProfile = try await service.fetchCurrentProfile()
            profile = fetchedProfile
            selectedGoals = Set(fetchedProfile.fitnessGoals)
            print("✅ UpdateGoalsViewModel.load: Loaded \(selectedGoals.count) goals")
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ UpdateGoalsViewModel.load: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Toggle Goal
    
    func toggleGoal(_ goal: FitnessGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }
    
    func isGoalSelected(_ goal: FitnessGoal) -> Bool {
        selectedGoals.contains(goal)
    }
    
    // MARK: - Save
    
    func save(using service: ProfileServiceProtocol) async -> Bool {
        guard var updatedProfile = profile else {
            errorMessage = "No profile to update"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        // Update the profile
        updatedProfile.fitnessGoals = Array(selectedGoals)
        updatedProfile.updatedAt = Date()
        
        do {
            let saved = try await service.updateProfile(updatedProfile)
            profile = saved
            successMessage = "Goals updated!"
            print("✅ UpdateGoalsViewModel.save: Saved \(selectedGoals.count) goals")
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ UpdateGoalsViewModel.save: \(error)")
            isSaving = false
            return false
        }
    }
}
