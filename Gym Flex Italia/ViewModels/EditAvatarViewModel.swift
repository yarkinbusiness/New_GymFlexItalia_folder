//
//  EditAvatarViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for editing user avatar style.
//

import Foundation
import Combine

/// ViewModel for avatar style editing
@MainActor
final class EditAvatarViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var profile: Profile?
    @Published var selectedStyle: AvatarStyle = .athlete
    
    // MARK: - Load
    
    func load(using service: ProfileServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProfile = try await service.fetchCurrentProfile()
            profile = fetchedProfile
            selectedStyle = fetchedProfile.avatarStyle
            print("✅ EditAvatarViewModel.load: Loaded profile with style \(selectedStyle.rawValue)")
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ EditAvatarViewModel.load: \(error)")
        }
        
        isLoading = false
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
        updatedProfile.avatarStyle = selectedStyle
        updatedProfile.updatedAt = Date()
        
        do {
            let saved = try await service.updateProfile(updatedProfile)
            profile = saved
            successMessage = "Avatar updated!"
            print("✅ EditAvatarViewModel.save: Saved avatar style \(selectedStyle.rawValue)")
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ EditAvatarViewModel.save: \(error)")
            isSaving = false
            return false
        }
    }
}
