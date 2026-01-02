//
//  LoadStateView.swift
//  Gym Flex Italia
//
//  Reusable loading and not-found state views.
//  See also: ErrorStateView.swift, EmptyStateView.swift
//

import SwiftUI

// MARK: - Loading View

/// Standard loading state view
struct LoadingStateView: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                .scaleEffect(1.5)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFonts.h4)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

// MARK: - Not Found View

/// Standard not found state for invalid routes or missing content
struct NotFoundView: View {
    let title: String
    let message: String
    let backAction: (() -> Void)?
    
    init(
        title: String = "Not Found",
        message: String = "The content you're looking for doesn't exist.",
        backAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.backAction = backAction
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(AppFonts.h3)
                .foregroundColor(.primary)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            
            if let backAction = backAction {
                Button(action: backAction) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.left")
                        Text("Go Back")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                }
                .padding(.top, Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

// MARK: - Previews

#Preview("Loading") {
    LoadingStateView(title: "Loading...", subtitle: "Please wait")
}

#Preview("Not Found") {
    NotFoundView(backAction: {})
}
