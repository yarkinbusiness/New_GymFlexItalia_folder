//
//  GroupsViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for groups discovery and management.
//  Uses DI via AppContainer - no legacy GroupsService.shared usage.
//

import Foundation
import Combine

/// ViewModel for groups discovery and management
@MainActor
final class GroupsViewModel: ObservableObject {
    
    @Published var allGroups: [FitnessGroup] = []
    @Published var myGroups: [FitnessGroup] = []
    @Published var filteredGroups: [FitnessGroup] = []
    @Published var selectedCategory: GroupCategory?
    @Published var searchQuery = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCreateGroup = false
    
    /// Current user ID (from mock data)
    private let currentUserId = MockDataStore.mockUserId
    
    // MARK: - Load Groups
    
    func load(using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            allGroups = try await service.fetchGroups()
            myGroups = try await service.fetchMyGroups(userId: currentUserId)
            filteredGroups = filterGroups(allGroups)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadAllGroups(using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            allGroups = try await service.fetchGroups()
            filteredGroups = filterGroups(allGroups)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMyGroups(using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            myGroups = try await service.fetchMyGroups(userId: currentUserId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search & Filter
    
    private func filterGroups(_ groups: [FitnessGroup]) -> [FitnessGroup] {
        var result = groups
        
        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.description?.lowercased().contains(query) ?? false)
            }
        }
        
        return result
    }
    
    func search() {
        filteredGroups = filterGroups(allGroups)
    }
    
    func clearSearch() {
        searchQuery = ""
        filteredGroups = filterGroups(allGroups)
    }
    
    func filterByCategory(_ category: GroupCategory?) {
        selectedCategory = category
        filteredGroups = filterGroups(allGroups)
    }
    
    // MARK: - Join/Leave Group
    
    func joinGroup(_ group: FitnessGroup, using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.joinGroup(id: group.id, userId: currentUserId)
            await loadMyGroups(using: service)
            await loadAllGroups(using: service)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func leaveGroup(_ group: FitnessGroup, using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.leaveGroup(id: group.id, userId: currentUserId)
            await loadMyGroups(using: service)
            await loadAllGroups(using: service)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Group
    
    func createGroup(
        name: String,
        description: String?,
        category: GroupCategory,
        isPublic: Bool,
        maxMembers: Int?,
        using service: GroupsChatServiceProtocol
    ) async -> FitnessGroup? {
        isLoading = true
        errorMessage = nil
        
        do {
            let group = try await service.createGroup(
                name: name,
                description: description,
                category: category,
                isPublic: isPublic,
                maxMembers: maxMembers
            )
            
            await loadMyGroups(using: service)
            await loadAllGroups(using: service)
            showCreateGroup = false
            isLoading = false
            return group
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    func isUserMember(of group: FitnessGroup) -> Bool {
        return myGroups.contains { $0.id == group.id }
    }
}
