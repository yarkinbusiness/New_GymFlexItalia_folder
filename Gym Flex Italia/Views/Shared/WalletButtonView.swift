//
//  WalletButtonView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import SwiftUI

/// Reusable wallet button component with real-time balance updates
struct WalletButtonView: View {
    @ObservedObject private var walletStore = WalletStore.shared
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                // Wallet icon - using asset name "wallet-icon" (add to Assets.xcassets)
                // Falls back to system icon if asset not found
                Group {
                    // Try to load custom wallet icon from assets
                    if UIImage(named: "wallet-icon") != nil {
                        Image("wallet-icon")
                            .resizable()
                            .renderingMode(.template)
                    } else {
                        // Fallback to system icon until asset is added
                        Image(systemName: "wallet.pass.fill")
                    }
                }
                .frame(width: 14, height: 14)
                .foregroundColor(AppColors.textHigh)
                
                Text(String(format: "€%.2f", walletStore.balance))
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.textHigh)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                // Brand color background with glass effect
                RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous)
                    .fill(AppColors.brand.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous)
                            .stroke(AppColors.brand.opacity(0.3), lineWidth: 1)
                    )
            )
            .glassBackground(cornerRadius: CornerRadii.md, opacity: 0.3, blur: 15)
        }
        .accessibilityLabel("Wallet balance: €\(String(format: "%.2f", walletStore.balance))")
        .accessibilityHint("Tap to open wallet")
    }
}

#Preview {
    WalletButtonView {
        print("Wallet tapped")
    }
    .padding()
    .background(AppColors.background)
}

