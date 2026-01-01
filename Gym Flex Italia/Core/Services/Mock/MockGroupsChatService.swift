//
//  MockGroupsChatService.swift
//  Gym Flex Italia
//
//  Mock implementation of GroupsChatServiceProtocol.
//  Uses MockGroupsStore for offline operation.
//

import Foundation

/// Mock implementation of groups and chat service.
/// Works entirely offline using MockGroupsStore.
final class MockGroupsChatService: GroupsChatServiceProtocol {
    
    // MARK: - Fetch Groups
    
    @MainActor
    func fetchGroups() async throws -> [FitnessGroup] {
        // Simulate network delay (200-500ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...500_000_000))
        
        // Ensure store is seeded
        MockGroupsStore.shared.seedIfNeeded()
        
        return MockGroupsStore.shared.allGroups()
    }
    
    @MainActor
    func fetchMyGroups(userId: String) async throws -> [FitnessGroup] {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        // Ensure store is seeded
        MockGroupsStore.shared.seedIfNeeded()
        
        return MockGroupsStore.shared.myGroups(userId: userId)
    }
    
    @MainActor
    func fetchGroup(id: String) async throws -> FitnessGroup {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        // Ensure store is seeded
        MockGroupsStore.shared.seedIfNeeded()
        
        guard let group = MockGroupsStore.shared.groupById(id) else {
            throw GroupsChatError.groupNotFound
        }
        
        return group
    }
    
    // MARK: - Create Group
    
    @MainActor
    func createGroup(
        name: String,
        description: String?,
        category: GroupCategory,
        isPublic: Bool,
        maxMembers: Int?
    ) async throws -> FitnessGroup {
        // Simulate network delay (300-500ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        
        let userId = MockDataStore.mockUserId
        let now = Date()
        
        let group = FitnessGroup(
            id: "group_\(UUID().uuidString.prefix(8))",
            name: name,
            description: description,
            coverImageURL: nil,
            category: category,
            tags: [],
            isPublic: isPublic,
            maxMembers: maxMembers,
            creatorId: userId,
            creatorName: "You",
            memberCount: 1,
            memberIds: [userId],
            city: nil,
            region: nil,
            totalWorkouts: 0,
            averageLevel: 0,
            createdAt: now,
            updatedAt: now
        )
        
        MockGroupsStore.shared.createGroup(group)
        
        print("✅ MockGroupsChatService.createGroup: \(name) (isPublic=\(isPublic))")
        return group
    }
    
    // MARK: - Join/Leave Group
    
    @MainActor
    func joinGroup(id: String, userId: String) async throws {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        MockGroupsStore.shared.joinGroup(groupId: id, userId: userId)
    }
    
    @MainActor
    func joinGroupAsMember(groupId: String) async throws -> Bool {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        let userId = MockDataStore.mockUserId
        
        // Verify group exists
        guard MockGroupsStore.shared.groupById(groupId) != nil else {
            throw GroupsChatError.groupNotFound
        }
        
        // Join the group
        MockGroupsStore.shared.joinGroup(groupId: groupId, userId: userId)
        
        print("✅ MockGroupsChatService.joinGroupAsMember: Joined group \(groupId)")
        return true
    }
    
    @MainActor
    func leaveGroup(id: String, userId: String) async throws {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        MockGroupsStore.shared.leaveGroup(groupId: id, userId: userId)
    }
    
    @MainActor
    func leaveGroup(groupId: String) async throws -> Bool {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        let userId = MockDataStore.mockUserId
        
        // Verify group exists
        guard MockGroupsStore.shared.groupById(groupId) != nil else {
            throw GroupsChatError.groupNotFound
        }
        
        // Leave the group
        MockGroupsStore.shared.leaveGroup(groupId: groupId, userId: userId)
        
        print("✅ MockGroupsChatService.leaveGroup: Left group \(groupId)")
        return true
    }
    
    // MARK: - Messages
    
    @MainActor
    func fetchMessages(groupId: String) async throws -> [Message] {
        // Simulate network delay (200-500ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...500_000_000))
        
        // Ensure store is seeded
        MockGroupsStore.shared.seedIfNeeded()
        
        return MockGroupsStore.shared.messagesForGroup(groupId)
    }
    
    @MainActor
    func sendMessage(groupId: String, text: String, userId: String, userName: String) async throws -> Message {
        // Simulate network delay (150-300ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 150_000_000...300_000_000))
        
        // Deterministic failure: message contains "FAIL"
        if text.uppercased().contains("FAIL") {
            print("❌ MockGroupsChatService.sendMessage: Deterministic failure triggered")
            throw GroupsChatError.messageFailed
        }
        
        let now = Date()
        
        let message = Message(
            id: "msg_\(UUID().uuidString.prefix(8))",
            groupId: groupId,
            userId: userId,
            userName: userName,
            userAvatarURL: nil,
            userAvatarLevel: 3,
            content: text,
            type: .text,
            attachmentURL: nil,
            attachmentType: nil,
            createdAt: now,
            updatedAt: nil,
            isEdited: false,
            isDeleted: false
        )
        
        MockGroupsStore.shared.sendMessage(message)
        
        print("💬 MockGroupsChatService.sendMessage: Sent to group \(groupId)")
        return message
    }
}
