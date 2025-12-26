//
//  CreateGroupView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Create group modal matching LED design
struct CreateGroupView: View {
    
    @Binding var isPresented: Bool
    @StateObject private var viewModel = GroupsViewModel()
    
    @State private var groupName = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var selectedCategory: GroupCategory = .general
    
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
                                        
                                        Text("Public")
                                            .font(AppFonts.body)
                                            .foregroundColor(isPublic ? AppColors.textHigh : AppColors.textDim)
                                        
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
                                        
                                        Text("Private")
                                            .font(AppFonts.body)
                                            .foregroundColor(!isPublic ? AppColors.textHigh : AppColors.textDim)
                                        
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
                                
                                if !isPublic {
                                    Text("Only invited friends can join")
                                        .font(AppFonts.bodySmall)
                                        .foregroundColor(AppColors.textDim)
                                        .padding(.leading, Spacing.xl)
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
                                Task {
                                    let success = await viewModel.createGroup(
                                        name: groupName,
                                        description: description.isEmpty ? nil : description,
                                        category: selectedCategory,
                                        isPublic: isPublic,
                                        maxMembers: nil
                                    )
                                    
                                    if success {
                                        isPresented = false
                                    }
                                }
                            } label: {
                                Text("Create Group")
                                    .font(AppFonts.label)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .background(AppGradients.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                            }
                            .disabled(groupName.isEmpty || viewModel.isLoading)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CreateGroupView(isPresented: .constant(true))
}

