//
//  GroupsViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
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
    
    private let groupsService = GroupsService.shared
    
    // MARK: - Load Groups
    func loadAllGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            allGroups = try await groupsService.fetchGroups(category: selectedCategory)
            filteredGroups = allGroups
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMyGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            myGroups = try await groupsService.fetchMyGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search
    func search() async {
        guard !searchQuery.isEmpty else {
            filteredGroups = allGroups
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            filteredGroups = try await groupsService.searchGroups(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        searchQuery = ""
        filteredGroups = allGroups
    }
    
    // MARK: - Filter by Category
    func filterByCategory(_ category: GroupCategory?) {
        selectedCategory = category
        Task {
            await loadAllGroups()
        }
    }
    
    // MARK: - Join/Leave Group
    func joinGroup(_ group: FitnessGroup) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await groupsService.joinGroup(id: group.id)
            await loadMyGroups()
            await loadAllGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func leaveGroup(_ group: FitnessGroup) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await groupsService.leaveGroup(id: group.id)
            await loadMyGroups()
            await loadAllGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Group
    func createGroup(name: String, description: String?, category: GroupCategory, isPublic: Bool, maxMembers: Int?) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await groupsService.createGroup(
                name: name,
                description: description,
                category: category,
                isPublic: isPublic,
                maxMembers: maxMembers
            )
            
            await loadMyGroups()
            showCreateGroup = false
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Helper Methods
    func isUserMember(of group: FitnessGroup) -> Bool {
        return myGroups.contains { $0.id == group.id }
    }
}

