//
//  GroupChatView.swift
//  Gym Flex Italia
//
//  Group chat view with messages and share button for private groups.
//  Shows Join UI for private groups when user is not a member.
//  Features: auto-scroll, join/leave toasts, Leave Group option.
//  Uses DI via AppContainer.
//

import SwiftUI

/// Group chat/detail view
struct GroupChatView: View {
    
    let groupId: String
    
    @StateObject private var viewModel = GroupChatViewModel()
    @Environment(\.appContainer) var appContainer
    @EnvironmentObject var router: AppRouter
    
    @State private var showShareSheet = false
    @State private var showLeaveConfirmation = false
    @State private var showJoinedToast = false
    @State private var showLeftToast = false
    @State private var scrollToMessageId: String?
    @FocusState private var isInputFocused: Bool
    
    /// Whether to show the chat content (messages + composer)
    private var showChatContent: Bool {
        guard let group = viewModel.group else { return false }
        // Show chat if: public group OR user is a member
        return group.isPublic || viewModel.isMember
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if showChatContent {
                    // Full chat experience - messages and composer
                    messagesListView
                    messageInputView
                } else if let group = viewModel.group {
                    // Private group, not a member - show join UI
                    joinGroupView(group)
                }
            }
            
            if viewModel.isLoading || viewModel.isJoining || viewModel.isLeaving {
                LoadingOverlayView()
            }
        }
        .navigationTitle(viewModel.group?.name ?? "Group Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    // Share button - ONLY for private groups when member
                    if let group = viewModel.group, group.isPrivate, viewModel.isMember {
                        Button {
                            DemoTapLogger.log("Group.ShareInvite.\(group.id)")
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                        }
                    }
                    
                    // Leave button - for private groups when member
                    if let group = viewModel.group, group.isPrivate, viewModel.isMember {
                        Menu {
                            Button(role: .destructive) {
                                showLeaveConfirmation = true
                            } label: {
                                Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let group = viewModel.group {
                ShareSheet(activityItems: [group.shareText, group.inviteLink])
            }
        }
        .confirmationDialog(
            "Leave Group",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) {
                Task {
                    let success = await viewModel.leaveGroup(using: appContainer.groupsChatService)
                    if success {
                        showLeftToast = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Leave this group? You will need an invite to rejoin.")
        }
        .task {
            await viewModel.loadGroup(groupId: groupId, using: appContainer.groupsChatService)
        }
        .refreshable {
            await viewModel.refreshMessages(using: appContainer.groupsChatService)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .toast("Joined group!", isPresented: $showJoinedToast)
        .toast("Left group", icon: "rectangle.portrait.and.arrow.right", iconColor: .orange, isPresented: $showLeftToast)
    }
    
    // MARK: - Join Group View (for non-members of private groups)
    
    private func joinGroupView(_ group: FitnessGroup) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Group Header (always visible)
                groupHeaderView(group)
                
                // Join Panel
                VStack(spacing: Spacing.lg) {
                    // Lock Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    // Text
                    VStack(spacing: Spacing.sm) {
                        Text("Private Group")
                            .font(AppFonts.h3)
                            .foregroundColor(.primary)
                        
                        Text("Join to view and send messages.")
                            .font(AppFonts.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Join Button
                    Button {
                        DemoTapLogger.log("Group.Join.\(group.id)")
                        Task {
                            let success = await viewModel.joinGroup(using: appContainer.groupsChatService)
                            if success {
                                showJoinedToast = true
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isJoining ? "Joining..." : "Join Group")
                        }
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                    }
                    .disabled(viewModel.isJoining)
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(Spacing.xl)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                .padding(.horizontal, Spacing.md)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Messages List
    
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    // Group Header
                    if let group = viewModel.group {
                        groupHeaderView(group)
                    }
                    
                    // Messages
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                        let showUserInfo = viewModel.shouldShowUserInfo(for: message, previousMessage: previousMessage)
                        
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: viewModel.isFromCurrentUser(message),
                            showUserInfo: showUserInfo
                        )
                        .id(message.id)
                    }
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.md)
            }
            .onChange(of: viewModel.messages.count) { oldValue, newValue in
                // Scroll to bottom when new message is added or on initial load
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                // Scroll to bottom after initial load completes
                if !isLoading && !viewModel.messages.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Group Header
    
    private func groupHeaderView(_ group: FitnessGroup) -> some View {
        VStack(spacing: Spacing.md) {
            // Group Icon
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: group.category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.brand)
            }
            
            // Group Info
            VStack(spacing: Spacing.xs) {
                Text(group.name)
                    .font(AppFonts.h3)
                    .foregroundColor(.primary)
                
                if let description = group.description {
                    Text(description)
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: Spacing.md) {
                    Label("\(group.memberCount) members", systemImage: "person.2.fill")
                    
                    Label(group.isPublic ? "Public" : "Private", systemImage: group.isPublic ? "globe" : "lock.fill")
                }
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
            }
            
            // Share Invite (private groups only, when member)
            if group.isPrivate && viewModel.isMember {
                Button {
                    DemoTapLogger.log("Group.ShareInviteHeader.\(group.id)")
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Share Invite Link")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(AppColors.brand.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Divider()
                .padding(.top, Spacing.md)
        }
        .padding(.bottom, Spacing.lg)
    }
    
    // MARK: - Message Input
    
    private var messageInputView: some View {
        HStack(spacing: Spacing.sm) {
            // Text Field
            TextField("Type a message...", text: $viewModel.messageText)
                .font(AppFonts.body)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                .focused($isInputFocused)
            
            // Send Button
            Button {
                Task {
                    _ = await viewModel.sendMessage(using: appContainer.groupsChatService)
                    // Auto-scroll happens via onChange
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.messageText.isEmpty ? Color.gray.opacity(0.3) : AppColors.brand)
                        .frame(width: 40, height: 40)
                    
                    if viewModel.isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let showUserInfo: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // User Info
                if showUserInfo && !isFromCurrentUser {
                    Text(message.userName ?? "User")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, Spacing.sm)
                }
                
                // Message Content
                Text(message.content)
                    .font(AppFonts.body)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        isFromCurrentUser
                            ? AppColors.brand
                            : Color(.secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                
                // Timestamp
                Text(formatTime(message.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.sm)
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        GroupChatView(groupId: "group_001")
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
