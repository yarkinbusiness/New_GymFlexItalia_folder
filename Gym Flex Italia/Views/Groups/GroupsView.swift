//
//  GroupsView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Groups view matching LED design
struct GroupsView: View {
    
    @StateObject private var viewModel = GroupsViewModel()
    @State private var showCreateGroup = false
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Groups List
                if viewModel.filteredGroups.isEmpty {
                    emptyStateView
                } else {
                    groupsList
                }
            }
            
            if viewModel.isLoading {
                LoadingOverlayView()
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView(isPresented: $showCreateGroup)
        }
        .task {
            await viewModel.loadAllGroups()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Groups")
                        .font(AppFonts.h1)
                        .foregroundColor(Color(.label))
                    
                    Text("Chat and motivate your workout buddies")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                // Create Group Button
                Button {
                    showCreateGroup = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(AppGradients.primary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Groups List
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(viewModel.filteredGroups) { group in
                    GroupCard(group: group)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.textDim)
            
            VStack(spacing: Spacing.sm) {
                Text("No Groups Yet")
                    .font(AppFonts.h3)
                    .foregroundColor(Color(.label))
                
                Text("Create or join a group to connect with others!")
                    .font(AppFonts.body)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showCreateGroup = true
            } label: {
                Text("Create Group")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxl)
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: FitnessGroup
    
    var body: some View {
        Button {
            // Navigate to group detail
        } label: {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.secondary)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: group.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.brand)
                }
                
                // Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(group.name)
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.textHigh)
                    
                    // Privacy Badge
                    HStack(spacing: 4) {
                        Image(systemName: group.isPublic ? "globe" : "lock.fill")
                            .font(.system(size: 10))
                        Text(group.isPublic ? "Public" : "Private")
                            .font(AppFonts.caption)
                    }
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.accent.opacity(0.15))
                    )
                    
                    // Meta
                    HStack(spacing: Spacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("26d ago")
                                .font(AppFonts.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(group.memberCount) member\(group.memberCount == 1 ? "" : "s")")
                                .font(AppFonts.caption)
                        }
                    }
                    .foregroundColor(AppColors.textDim)
                }
                
                Spacer()
            }
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GroupsView()
}
