//
//  GroupChatViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
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
    @Published var errorMessage: String?
    
    private let groupsService = GroupsService.shared
    private let realtimeService = RealtimeService.shared
    private let authService = AuthService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Group & Messages
    func loadGroup(groupId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            group = try await groupsService.fetchGroup(id: groupId)
            await loadMessages(groupId: groupId)
            subscribeToMessages(groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadMessages(groupId: String) async {
        do {
            messages = try await groupsService.fetchMessages(groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let groupId = group?.id else {
            return
        }
        
        isSending = true
        let textToSend = messageText
        messageText = "" // Clear input immediately
        
        do {
            let message = try await groupsService.sendMessage(
                groupId: groupId,
                content: textToSend,
                type: .text
            )
            
            // Message will be added via realtime subscription
            // But add it optimistically if realtime is slow
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            errorMessage = error.localizedDescription
            messageText = textToSend // Restore text on error
        }
        
        isSending = false
    }
    
    // MARK: - Realtime Subscription
    private func subscribeToMessages(groupId: String) {
        realtimeService.subscribeToGroupChat(groupId: groupId) { [weak self] newMessage in
            Task { @MainActor in
                // Only add if not already in list
                if !(self?.messages.contains(where: { $0.id == newMessage.id }) ?? false) {
                    self?.messages.append(newMessage)
                }
            }
        }
    }
    
    // MARK: - Load More Messages
    func loadMoreMessages() async {
        guard let groupId = group?.id,
              let oldestMessage = messages.first else {
            return
        }
        
        do {
            let olderMessages = try await groupsService.fetchMessages(
                groupId: groupId,
                before: oldestMessage.createdAt
            )
            
            messages.insert(contentsOf: olderMessages, at: 0)
        } catch {
            print("Failed to load more messages: \(error)")
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
        return message.userId == authService.currentUser?.id
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if let groupId = group?.id {
            realtimeService.unsubscribeFromGroupChat(groupId: groupId)
        }
    }
}

