//
//  EditAvatarView.swift
//  Gym Flex Italia
//
//  View for editing user avatar style.
//

import SwiftUI

/// Avatar style editing view
struct EditAvatarView: View {
    
    @StateObject private var viewModel = EditAvatarViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.appContainer) var appContainer
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.profile == nil {
                errorView(error)
            } else {
                contentView
            }
        }
        .navigationTitle("Edit Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        saveAvatar()
                    }
                    .disabled(viewModel.profile == nil)
                }
            }
        }
        .task {
            await viewModel.load(using: appContainer.profileService)
        }
        .toast("Avatar updated!", isPresented: .constant(viewModel.successMessage != nil))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.danger)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.load(using: appContainer.profileService)
                }
            }
            .font(AppFonts.label)
            .foregroundColor(AppColors.brand)
        }
        .padding()
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Current Avatar Preview
                avatarPreview
                
                // Style Selection
                styleSelectionGrid
                
                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.danger)
                        
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.danger)
                    }
                    .padding()
                    .background(AppColors.danger.opacity(0.1))
                    .cornerRadius(CornerRadii.md)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Avatar Preview
    
    private var avatarPreview: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppGradients.primary)
                    .frame(width: 120, height: 120)
                
                Text(avatarEmoji(for: viewModel.selectedStyle))
                    .font(.system(size: 60))
            }
            
            Text(viewModel.selectedStyle.displayName)
                .font(AppFonts.h3)
                .foregroundColor(.primary)
        }
        .padding(.vertical, Spacing.lg)
    }
    
    // MARK: - Style Selection Grid
    
    private var styleSelectionGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Choose Your Avatar Style")
                .font(AppFonts.h4)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(AvatarStyle.allCases, id: \.self) { style in
                    avatarStyleCard(style)
                }
            }
        }
    }
    
    private func avatarStyleCard(_ style: AvatarStyle) -> some View {
        let isSelected = viewModel.selectedStyle == style
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedStyle = style
            }
        } label: {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppGradients.primary : LinearGradient(colors: [Color(.tertiarySystemFill)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 70, height: 70)
                    
                    Text(avatarEmoji(for: style))
                        .font(.system(size: 32))
                }
                
                Text(style.displayName)
                    .font(AppFonts.caption)
                    .foregroundColor(isSelected ? AppColors.brand : .secondary)
            }
            .padding(Spacing.md)
            .background(isSelected ? AppColors.brand.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.lg)
                    .stroke(isSelected ? AppColors.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func avatarEmoji(for style: AvatarStyle) -> String {
        switch style {
        case .warrior: return "⚔️"
        case .athlete: return "🏃"
        case .ninja: return "🥷"
        case .champion: return "🏆"
        case .beast: return "🦁"
        }
    }
    
    private func saveAvatar() {
        Task {
            let success = await viewModel.save(using: appContainer.profileService)
            if success {
                // Pop back after short delay
                try? await Task.sleep(nanoseconds: 800_000_000)
                router.pop()
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditAvatarView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
