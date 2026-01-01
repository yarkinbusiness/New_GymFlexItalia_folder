//
//  GroupInviteErrorView.swift
//  Gym Flex Italia
//
//  Error view shown when an invite link is invalid or expired.
//

import SwiftUI

/// View shown when a group invite link is invalid or expired
struct GroupInviteErrorView: View {
    
    let message: String
    
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Error Icon
            ZStack {
                Circle()
                    .fill(AppColors.danger.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.danger)
            }
            
            // Title
            Text("Group Not Found")
                .font(AppFonts.h2)
                .foregroundColor(.primary)
            
            // Body
            Text("This invite link is invalid, expired, or the group no longer exists.")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            // Actions
            VStack(spacing: Spacing.md) {
                Button {
                    DemoTapLogger.log("GroupInviteError.BackToGroups")
                    router.resetToRoot()
                } label: {
                    Text("Back to Groups")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
                
                Button {
                    DemoTapLogger.log("GroupInviteError.GoHome")
                    router.switchToTab(.home)
                } label: {
                    Text("Go Home")
                        .font(AppFonts.label)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Invite Error")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GroupInviteErrorView(message: "Group not found or invite expired")
    }
    .environmentObject(AppRouter())
}
