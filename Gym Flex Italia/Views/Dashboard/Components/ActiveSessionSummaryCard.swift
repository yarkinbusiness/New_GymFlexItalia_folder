//
//  ActiveSessionSummaryCard.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import SwiftUI

struct ActiveSessionSummaryCard: View {
    let booking: Booking
    let onViewQRCode: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: ActiveSessionViewModel
    @State private var showCancelConfirmation = false
    
    init(booking: Booking, onViewQRCode: @escaping () -> Void, onCancel: @escaping () -> Void = {}) {
        self.booking = booking
        self.onViewQRCode = onViewQRCode
        self.onCancel = onCancel
        _viewModel = StateObject(wrappedValue: ActiveSessionViewModel(booking: booking))
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Glow Effect
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .blur(radius: 40)
                    .offset(y: -20)
                
                VStack(spacing: Spacing.xs) {
                    // Status Badge
                    Text("Active Session")
                        .font(AppFonts.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.brand)
                        )
                        .padding(.bottom, Spacing.sm)
                    
                    // Gym Name
                    Text(booking.gymName ?? "Gym")
                        .font(AppFonts.h4)
                        .foregroundColor(.white)
                    
                    // Address
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(booking.gymAddress ?? "")
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.textDim)
                    
                    // Timer
                    Text(viewModel.formattedTimeRemaining)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.accent)
                        .padding(.top, Spacing.sm)
                        .shadow(color: AppColors.accent.opacity(0.5), radius: 10, x: 0, y: 0)
                }
            }
            .padding(.top, Spacing.md)
            
            // Buttons
            VStack(spacing: Spacing.sm) {
                // View QR Code Button
                Button(action: onViewQRCode) {
                    Text("View QR Code")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                }
                
                // Cancel Session Button
                Button {
                    DemoTapLogger.log("Home.ActiveSession.CancelTap")
                    showCancelConfirmation = true
                } label: {
                    Text("Cancel Session")
                        .font(AppFonts.label)
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.danger.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                }
            }
        }
        .padding(Spacing.xl)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadii.xl)
                .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
        )
        .alert("Cancel Session?", isPresented: $showCancelConfirmation) {
            Button("Keep Session", role: .cancel) {}
            Button("Cancel Session", role: .destructive) {
                DemoTapLogger.log("Home.ActiveSession.Cancel")
                onCancel()
            }
        } message: {
            Text("No refund will be issued. Are you sure you want to cancel your active session?")
        }
    }
}
