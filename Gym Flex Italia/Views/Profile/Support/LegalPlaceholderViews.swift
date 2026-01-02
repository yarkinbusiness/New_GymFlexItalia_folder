//
//  LegalPlaceholderViews.swift
//  Gym Flex Italia
//
//  Placeholder views for Terms and Privacy.
//

import SwiftUI

/// Terms of Service placeholder view
struct TermsPlaceholderView: View {
    var body: some View {
        LegalPlaceholderContent(
            title: "Terms of Service",
            icon: "doc.text.fill",
            message: "Our Terms of Service document is being prepared and will be available soon."
        )
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Privacy Policy placeholder view
struct PrivacyPlaceholderView: View {
    var body: some View {
        LegalPlaceholderContent(
            title: "Privacy Policy",
            icon: "hand.raised.fill",
            message: "Our Privacy Policy document is being prepared and will be available soon."
        )
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Shared legal placeholder content
private struct LegalPlaceholderContent: View {
    let title: String
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.brand)
            }
            
            Text(title)
                .font(AppFonts.h2)
                .foregroundColor(.primary)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            Text("Coming Soon")
                .font(AppFonts.label)
                .foregroundColor(AppColors.brand)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.brand.opacity(0.15))
                .clipShape(Capsule())
            
            Spacer()
            
            // Footer
            Text("For immediate legal inquiries, please contact legal@gymflex.com")
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview("Terms") {
    NavigationStack {
        TermsPlaceholderView()
    }
}

#Preview("Privacy") {
    NavigationStack {
        PrivacyPlaceholderView()
    }
}
