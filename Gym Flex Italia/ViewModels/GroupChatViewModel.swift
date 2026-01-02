//
//  GroupChatViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for group chat functionality.
//  Uses DI via AppContainer - no legacy GroupsService.shared or RealtimeService usage.
//

import Foundation
import Combine

/// ViewModel for group chat functionality
@MainActor
final class GroupChatViewModel: ObservableObject {
    
    @Published var group: FitnessGroup?
    @Published var messages: [Message] = []
    @Published var messageText = ""
    
    @Published var isLoading = false
    @Published var isSending = false
    @Published var isJoining = false
    @Published var isLeaving = false
    @Published var errorMessage: String?
    
    /// Whether the current user is a member of this group
    @Published var isMember = false
    
    /// Whether join was just successful (for toast display)
    @Published var didJoinSuccessfully = false
    
    /// Whether leave was just successful (for toast display)
    @Published var didLeaveSuccessfully = false
    
    /// Current user ID and name (from mock data)
    private let currentUserId = MockDataStore.mockUserId
    private let currentUserName = "You"
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Group & Messages
    
    func loadGroup(groupId: String, using service: GroupsChatServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            group = try await service.fetchGroup(id: groupId)
            
            // Check membership status
            refreshMembership(groupId: groupId)
            
            // Only load messages if member (or public group)
            if isMember {
                messages = try await service.fetchMessages(groupId: groupId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Refresh membership status from store
    func refreshMembership(groupId: String) {
        isMember = MockGroupsStore.shared.isMember(groupId: groupId, userId: currentUserId)
        #if DEBUG
        print("👤 GroupChatViewModel.refreshMembership: groupId=\(groupId), isMember=\(isMember)")
        #endif
    }
    
    func refreshMessages(using service: GroupsChatServiceProtocol) async {
        guard let groupId = group?.id else { return }
        
        do {
            messages = try await service.fetchMessages(groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Join Group
    
    func joinGroup(using service: GroupsChatServiceProtocol) async -> Bool {
        guard let groupId = group?.id else { return false }
        
        isJoining = true
        errorMessage = nil
        didJoinSuccessfully = false
        
        do {
            _ = try await service.joinGroupAsMember(groupId: groupId)
            
            // Refresh membership status
            refreshMembership(groupId: groupId)
            
            // Load messages now that we're a member
            if isMember {
                messages = try await service.fetchMessages(groupId: groupId)
            }
            
            didJoinSuccessfully = true
            DemoTapLogger.log("Group.Join.Success.\(groupId)")
            #if DEBUG
            print("✅ GroupChatViewModel.joinGroup: Successfully joined \(groupId)")
            #endif
            isJoining = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ GroupChatViewModel.joinGroup: Failed - \(error.localizedDescription)")
            #endif
            isJoining = false
            return false
        }
    }
    
    // MARK: - Leave Group
    
    func leaveGroup(using service: GroupsChatServiceProtocol) async -> Bool {
        guard let groupId = group?.id else { return false }
        
        isLeaving = true
        errorMessage = nil
        didLeaveSuccessfully = false
        
        do {
            _ = try await service.leaveGroup(groupId: groupId)
            
            // Refresh membership status
            refreshMembership(groupId: groupId)
            
            // Clear messages since no longer a member of private group
            if let group = group, group.isPrivate && !isMember {
                messages = []
            }
            
            didLeaveSuccessfully = true
            DemoTapLogger.log("Group.Leave.Success.\(groupId)")
            #if DEBUG
            print("✅ GroupChatViewModel.leaveGroup: Successfully left \(groupId)")
            #endif
            isLeaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ GroupChatViewModel.leaveGroup: Failed - \(error.localizedDescription)")
            #endif
            isLeaving = false
            return false
        }
    }
    
    // MARK: - Send Message
    
    func sendMessage(using service: GroupsChatServiceProtocol) async -> Bool {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let groupId = group?.id else {
            return false
        }
        
        isSending = true
        let textToSend = messageText
        messageText = "" // Clear input immediately
        
        do {
            let message = try await service.sendMessage(
                groupId: groupId,
                text: textToSend,
                userId: currentUserId,
                userName: currentUserName
            )
            
            // Add message to list
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
            
            isSending = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            messageText = textToSend // Restore text on error
            isSending = false
            return false
        }
    }
    
    // MARK: - Message Grouping
    
    func shouldShowUserInfo(for message: Message, previousMessage: Message?) -> Bool {
        guard let previous = previousMessage else { return true }
        
        // Show user info if different user or time gap > 5 minutes
        if message.userId != previous.userId {
            return true
        }
        
        let timeGap = message.createdAt.timeIntervalSince(previous.createdAt)
        return timeGap > 300 // 5 minutes
    }
    
    func isFromCurrentUser(_ message: Message) -> Bool {
        return message.userId == currentUserId
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // No realtime subscriptions to clean up in mock implementation
    }
}
