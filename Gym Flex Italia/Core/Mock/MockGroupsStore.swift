//
//  MockGroupsStore.swift
//  Gym Flex Italia
//
//  Single source of truth for groups and messages data.
//  Persisted to UserDefaults for offline operation.
//

import Foundation
import Combine

/// Persisted groups data structure
struct PersistedGroupsData: Codable {
    var groups: [FitnessGroup]
    
    static let empty = PersistedGroupsData(groups: [])
}

/// Persisted messages data structure
struct PersistedMessagesData: Codable {
    var messagesByGroupId: [String: [Message]]
    
    static let empty = PersistedMessagesData(messagesByGroupId: [:])
}

/// Shared groups store that maintains consistent state for offline groups/chat.
/// Used by MockGroupsChatService.
/// Persists to UserDefaults for data retention across app launches.
@MainActor
final class MockGroupsStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = MockGroupsStore()
    
    // MARK: - Persistence Keys
    
    private static let groupsKey = "groups_store_v1"
    private static let messagesKey = "groups_messages_store_v1"
    
    // MARK: - State
    
    /// All groups in the store
    @Published private(set) var groups: [FitnessGroup] = []
    
    /// Messages organized by group ID
    @Published private(set) var messagesByGroupId: [String: [Message]] = [:]
    
    /// Whether initial seed data has been loaded
    private var hasSeeded = false
    
    private init() {
        loadGroups()
        loadMessages()
        print("👥 MockGroupsStore.init: Loaded \(groups.count) groups, \(messagesByGroupId.count) message threads")
    }
    
    // MARK: - Persistence (Groups)
    
    func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: Self.groupsKey) else {
            print("👥 MockGroupsStore.loadGroups: No persisted groups")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(PersistedGroupsData.self, from: data)
            groups = decoded.groups
            print("👥 MockGroupsStore.loadGroups: Loaded \(groups.count) groups")
        } catch {
            print("⚠️ MockGroupsStore.loadGroups: Failed to decode: \(error)")
        }
    }
    
    func saveGroups() {
        let data = PersistedGroupsData(groups: groups)
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.groupsKey)
            print("👥 MockGroupsStore.saveGroups: Saved \(groups.count) groups")
        } catch {
            print("⚠️ MockGroupsStore.saveGroups: Failed to encode: \(error)")
        }
    }
    
    // MARK: - Persistence (Messages)
    
    func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: Self.messagesKey) else {
            print("👥 MockGroupsStore.loadMessages: No persisted messages")
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(PersistedMessagesData.self, from: data)
            messagesByGroupId = decoded.messagesByGroupId
            print("👥 MockGroupsStore.loadMessages: Loaded messages for \(messagesByGroupId.count) groups")
        } catch {
            print("⚠️ MockGroupsStore.loadMessages: Failed to decode: \(error)")
        }
    }
    
    func saveMessages() {
        let data = PersistedMessagesData(messagesByGroupId: messagesByGroupId)
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: Self.messagesKey)
            print("👥 MockGroupsStore.saveMessages: Saved messages for \(messagesByGroupId.count) groups")
        } catch {
            print("⚠️ MockGroupsStore.saveMessages: Failed to encode: \(error)")
        }
    }
    
    // MARK: - Seeding
    
    func seedIfNeeded() {
        guard !hasSeeded else { return }
        
        if !groups.isEmpty {
            print("🛡️ MockGroupsStore.seedIfNeeded: Skipping seed - \(groups.count) groups already exist")
            hasSeeded = true
            return
        }
        
        hasSeeded = true
        groups = Self.generateSeedGroups()
        messagesByGroupId = Self.generateSeedMessages(for: groups)
        saveGroups()
        saveMessages()
        print("🌱 MockGroupsStore.seedIfNeeded: Seeded \(groups.count) groups with messages")
    }
    
    // MARK: - Query Methods
    
    func allGroups() -> [FitnessGroup] {
        groups.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func groupById(_ id: String) -> FitnessGroup? {
        groups.first { $0.id == id }
    }
    
    func messagesForGroup(_ groupId: String) -> [Message] {
        messagesByGroupId[groupId]?.sorted { $0.createdAt < $1.createdAt } ?? []
    }
    
    func myGroups(userId: String) -> [FitnessGroup] {
        groups.filter { $0.memberIds.contains(userId) }
    }
    
    /// Check if a user is a member of a group.
    /// For public groups, always returns true (open access).
    /// For private groups, checks if user is in memberIds.
    func isMember(groupId: String, userId: String) -> Bool {
        guard let group = groupById(groupId) else {
            return false
        }
        
        // Public groups are always accessible
        if group.isPublic {
            return true
        }
        
        // Private groups require membership
        return group.memberIds.contains(userId)
    }
    
    // MARK: - Mutation Methods
    
    func createGroup(_ group: FitnessGroup) {
        groups.append(group)
        messagesByGroupId[group.id] = []
        saveGroups()
        saveMessages()
        print("✅ MockGroupsStore.createGroup: Created \(group.name) (id=\(group.id), isPublic=\(group.isPublic))")
    }
    
    func sendMessage(_ message: Message) {
        var messages = messagesByGroupId[message.groupId] ?? []
        messages.append(message)
        messagesByGroupId[message.groupId] = messages
        saveMessages()
        print("💬 MockGroupsStore.sendMessage: Added message to group \(message.groupId)")
    }
    
    func joinGroup(groupId: String, userId: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        
        if !groups[index].memberIds.contains(userId) {
            groups[index].memberIds.append(userId)
            groups[index].memberCount += 1
            groups[index].updatedAt = Date()
            saveGroups()
            print("✅ MockGroupsStore.joinGroup: User \(userId) joined group \(groupId)")
        }
    }
    
    func leaveGroup(groupId: String, userId: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        
        if let memberIndex = groups[index].memberIds.firstIndex(of: userId) {
            groups[index].memberIds.remove(at: memberIndex)
            groups[index].memberCount = max(0, groups[index].memberCount - 1)
            groups[index].updatedAt = Date()
            saveGroups()
            print("✅ MockGroupsStore.leaveGroup: User \(userId) left group \(groupId)")
        }
    }
    
    // MARK: - Seed Data Generation
    
    private static func generateSeedGroups() -> [FitnessGroup] {
        let now = Date()
        let calendar = Calendar.current
        let userId = MockDataStore.mockUserId
        
        return [
            FitnessGroup(
                id: "group_001",
                name: "Rome Early Birds 🌅",
                description: "Early morning workout crew in Rome. We hit the gym at 6 AM!",
                coverImageURL: nil,
                category: .cardio,
                tags: ["morning", "cardio", "rome"],
                isPublic: true,
                maxMembers: 50,
                creatorId: "user_marco",
                creatorName: "Marco R.",
                memberCount: 23,
                memberIds: [userId, "user_marco", "user_lucia", "user_antonio"],
                city: "Rome",
                region: "Lazio",
                totalWorkouts: 156,
                averageLevel: 3.5,
                createdAt: calendar.date(byAdding: .day, value: -60, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -2, to: now)!
            ),
            FitnessGroup(
                id: "group_002",
                name: "Strength Squad 💪",
                description: "Serious lifters only. Share PRs, form checks, and motivation.",
                coverImageURL: nil,
                category: .strength,
                tags: ["strength", "powerlifting", "bodybuilding"],
                isPublic: true,
                maxMembers: 100,
                creatorId: "user_giuseppe",
                creatorName: "Giuseppe M.",
                memberCount: 67,
                memberIds: [userId, "user_giuseppe", "user_francesca"],
                city: "Milan",
                region: "Lombardy",
                totalWorkouts: 892,
                averageLevel: 4.2,
                createdAt: calendar.date(byAdding: .day, value: -120, to: now)!,
                updatedAt: calendar.date(byAdding: .minute, value: -45, to: now)!
            ),
            FitnessGroup(
                id: "group_003",
                name: "Yoga Flow Italia 🧘",
                description: "Daily yoga practice and mindfulness. All levels welcome.",
                coverImageURL: nil,
                category: .yoga,
                tags: ["yoga", "mindfulness", "flexibility"],
                isPublic: true,
                maxMembers: 80,
                creatorId: "user_chiara",
                creatorName: "Chiara B.",
                memberCount: 45,
                memberIds: ["user_chiara", "user_sofia"],
                city: nil,
                region: nil,
                totalWorkouts: 234,
                averageLevel: 2.8,
                createdAt: calendar.date(byAdding: .day, value: -90, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            FitnessGroup(
                id: "group_004",
                name: "Private Workout Partners",
                description: "Invite-only group for trusted workout buddies.",
                coverImageURL: nil,
                category: .general,
                tags: ["private", "friends"],
                isPublic: false,
                maxMembers: 10,
                creatorId: userId,
                creatorName: "You",
                memberCount: 4,
                memberIds: [userId, "user_friend1", "user_friend2", "user_friend3"],
                city: "Rome",
                region: "Lazio",
                totalWorkouts: 28,
                averageLevel: 3.0,
                createdAt: calendar.date(byAdding: .day, value: -30, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -6, to: now)!
            ),
            FitnessGroup(
                id: "group_005",
                name: "CrossFit Roma Elite",
                description: "Private CrossFit community for experienced athletes.",
                coverImageURL: nil,
                category: .crossfit,
                tags: ["crossfit", "wod", "elite"],
                isPublic: false,
                maxMembers: 20,
                creatorId: "user_coach",
                creatorName: "Coach Paolo",
                memberCount: 18,
                memberIds: [userId, "user_coach", "user_athlete1"],
                city: "Rome",
                region: "Lazio",
                totalWorkouts: 456,
                averageLevel: 4.5,
                createdAt: calendar.date(byAdding: .day, value: -180, to: now)!,
                updatedAt: calendar.date(byAdding: .hour, value: -1, to: now)!
            ),
            FitnessGroup(
                id: "group_006",
                name: "Runners of Rome 🏃",
                description: "Weekly group runs around historic Rome landmarks.",
                coverImageURL: nil,
                category: .running,
                tags: ["running", "outdoor", "rome"],
                isPublic: true,
                maxMembers: 200,
                creatorId: "user_runner",
                creatorName: "Alessandro T.",
                memberCount: 89,
                memberIds: ["user_runner", "user_maria"],
                city: "Rome",
                region: "Lazio",
                totalWorkouts: 312,
                averageLevel: 3.2,
                createdAt: calendar.date(byAdding: .day, value: -200, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -3, to: now)!
            )
        ]
    }
    
    private static func generateSeedMessages(for groups: [FitnessGroup]) -> [String: [Message]] {
        var result: [String: [Message]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        let sampleContents = [
            "Great workout today! 💪",
            "Who's coming to the gym tomorrow morning?",
            "Just hit a new PR! 🎉",
            "Remember to stretch after your workout",
            "Anyone want to try that new HIIT class?",
            "Feeling sore but happy 😅",
            "Don't forget to stay hydrated!",
            "Who's up for a 5K this weekend?",
            "Just finished my cardio session",
            "The gym was packed today",
            "Great form on those squats!",
            "Rest day today, see you all tomorrow",
            "What's everyone's favorite pre-workout?",
            "Crushing legs day! 🦵",
            "Morning workout done ✅",
            "Thanks for the motivation everyone!",
            "New workout plan starts Monday",
            "Who wants to be gym buddies?",
            "Just signed up for a fitness challenge",
            "Recovery is just as important as training",
            "Yoga session was amazing today",
            "Finally mastered that exercise!",
            "Consistency is key 🔑",
            "Push yourself but listen to your body",
            "Weekend warrior mode activated!"
        ]
        
        let userNames = ["Marco R.", "Lucia P.", "Antonio G.", "Chiara B.", "Giuseppe M.", "Sofia L.", "Coach Paolo", "Alessandro T.", "You"]
        let userIds = ["user_marco", "user_lucia", "user_antonio", "user_chiara", "user_giuseppe", "user_sofia", "user_coach", "user_runner", MockDataStore.mockUserId]
        
        for group in groups {
            var messages: [Message] = []
            let messageCount = Int.random(in: 10...25)
            
            for i in 0..<messageCount {
                let hoursAgo = Double(messageCount - i) * 2.5 + Double.random(in: 0...2)
                let createdAt = calendar.date(byAdding: .hour, value: -Int(hoursAgo), to: now)!
                
                let userIndex = i % userIds.count
                let content = sampleContents[i % sampleContents.count]
                
                let message = Message(
                    id: "msg_\(group.id)_\(String(format: "%03d", i + 1))",
                    groupId: group.id,
                    userId: userIds[userIndex],
                    userName: userNames[userIndex],
                    userAvatarURL: nil,
                    userAvatarLevel: Int.random(in: 1...5),
                    content: content,
                    type: .text,
                    attachmentURL: nil,
                    attachmentType: nil,
                    createdAt: createdAt,
                    updatedAt: nil,
                    isEdited: false,
                    isDeleted: false
                )
                messages.append(message)
            }
            
            result[group.id] = messages
        }
        
        return result
    }
    
    // MARK: - Debug
    
    func reset() {
        groups = []
        messagesByGroupId = [:]
        hasSeeded = false
        saveGroups()
        saveMessages()
        print("🔄 MockGroupsStore.reset: Store cleared")
    }
}
