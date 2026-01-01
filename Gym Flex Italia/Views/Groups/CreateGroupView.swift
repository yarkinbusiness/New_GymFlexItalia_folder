//
//  CreateGroupView.swift
//  Gym Flex Italia
//
//  Create group modal using DI via AppContainer.
//

import SwiftUI

/// Create group modal matching LED design
struct CreateGroupView: View {
    
    @Binding var isPresented: Bool
    var onGroupCreated: ((FitnessGroup?) -> Void)? = nil
    
    @EnvironmentObject var viewModel: GroupsViewModel
    @Environment(\.appContainer) var appContainer
    
    @State private var groupName = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var selectedCategory: GroupCategory = .general
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Dark background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Create New Group")
                        .font(AppFonts.h2)
                        .foregroundColor(AppColors.textHigh)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textHigh)
                            .frame(width: 32, height: 32)
                            .glassBackground(cornerRadius: CornerRadii.sm)
                    }
                }
                .padding(Spacing.lg)
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Error Banner
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                            }
                            .font(AppFonts.bodySmall)
                            .foregroundColor(.white)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.danger)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.sm))
                        }
                        
                        // Group Name
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Group Name")
                                .font(AppFonts.h5)
                                .foregroundColor(AppColors.textHigh)
                            
                            TextField("Enter group name...", text: $groupName)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textHigh)
                                .padding(Spacing.md)
                                .glassBackground(cornerRadius: CornerRadii.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadii.md)
                                        .stroke(AppColors.brand, lineWidth: 2)
                                )
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Description (optional)")
                                .font(AppFonts.h5)
                                .foregroundColor(AppColors.textHigh)
                            
                            TextEditor(text: $description)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textHigh)
                                .frame(height: 100)
                                .padding(Spacing.sm)
                                .glassBackground(cornerRadius: CornerRadii.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadii.md)
                                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Privacy
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Privacy")
                                .font(AppFonts.h5)
                                .foregroundColor(AppColors.textHigh)
                            
                            VStack(spacing: Spacing.sm) {
                                // Public Option
                                Button {
                                    isPublic = true
                                } label: {
                                    HStack {
                                        Image(systemName: "globe")
                                            .font(.system(size: 18))
                                            .foregroundColor(isPublic ? AppColors.textHigh : AppColors.textDim)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Public")
                                                .font(AppFonts.body)
                                                .foregroundColor(isPublic ? AppColors.textHigh : AppColors.textDim)
                                            
                                            Text("Anyone can find and join")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textDim)
                                        }
                                        
                                        Spacer()
                                        
                                        if isPublic {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppColors.brand)
                                        }
                                    }
                                    .padding(Spacing.md)
                                    .background(
                                        isPublic
                                            ? AppColors.secondary
                                            : Color.clear
                                    )
                                    .glassBackground(cornerRadius: CornerRadii.md)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Private Option
                                Button {
                                    isPublic = false
                                } label: {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(!isPublic ? AppColors.textHigh : AppColors.textDim)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Private")
                                                .font(AppFonts.body)
                                                .foregroundColor(!isPublic ? AppColors.textHigh : AppColors.textDim)
                                            
                                            Text("Only invited friends can join")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.textDim)
                                        }
                                        
                                        Spacer()
                                        
                                        if !isPublic {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppColors.brand)
                                        }
                                    }
                                    .padding(Spacing.md)
                                    .background(
                                        !isPublic
                                            ? AppColors.secondary
                                            : Color.clear
                                    )
                                    .glassBackground(cornerRadius: CornerRadii.md)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Category Picker
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Category")
                                .font(AppFonts.h5)
                                .foregroundColor(AppColors.textHigh)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(GroupCategory.allCases, id: \.self) { category in
                                        Button {
                                            selectedCategory = category
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: category.icon)
                                                Text(category.displayName)
                                            }
                                            .font(AppFonts.caption)
                                            .foregroundColor(selectedCategory == category ? .white : AppColors.textDim)
                                            .padding(.horizontal, Spacing.md)
                                            .padding(.vertical, Spacing.sm)
                                            .background(
                                                selectedCategory == category
                                                    ? AppColors.brand
                                                    : AppColors.secondary
                                            )
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: Spacing.md) {
                            Button {
                                isPresented = false
                            } label: {
                                Text("Cancel")
                                    .font(AppFonts.label)
                                    .foregroundColor(AppColors.textHigh)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .glassBackground(cornerRadius: CornerRadii.md)
                            }
                            
                            Button {
                                createGroup()
                            } label: {
                                HStack {
                                    if isCreating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(isCreating ? "Creating..." : "Create Group")
                                }
                                .font(AppFonts.label)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(AppGradients.primary)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                            }
                            .disabled(groupName.isEmpty || isCreating)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func createGroup() {
        guard !groupName.isEmpty else { return }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            let group = await viewModel.createGroup(
                name: groupName,
                description: description.isEmpty ? nil : description,
                category: selectedCategory,
                isPublic: isPublic,
                maxMembers: nil,
                using: appContainer.groupsChatService
            )
            
            isCreating = false
            
            if let group = group {
                DemoTapLogger.log("Groups.Created", context: "id: \(group.id), isPublic: \(isPublic)")
                isPresented = false
                onGroupCreated?(group)
            } else {
                errorMessage = viewModel.errorMessage ?? "Failed to create group"
            }
        }
    }
}

#Preview {
    CreateGroupView(isPresented: .constant(true))
        .environmentObject(GroupsViewModel())
        .environment(\.appContainer, .demo())
}
