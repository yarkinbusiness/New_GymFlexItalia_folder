//
//  ActiveSessionSummaryCard.swift
//  Gym Flex Italia
//
//  Hero card for active session on Home - the signature moment
//

import SwiftUI

struct ActiveSessionSummaryCard: View {
    let booking: Booking
    let onViewQRCode: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: ActiveSessionViewModel
    @State private var showCancelConfirmation = false
    
    // Environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.gfTheme) private var theme
    
    init(booking: Booking, onViewQRCode: @escaping () -> Void, onCancel: @escaping () -> Void = {}) {
        self.booking = booking
        self.onViewQRCode = onViewQRCode
        self.onCancel = onCancel
        _viewModel = StateObject(wrappedValue: ActiveSessionViewModel(booking: booking))
    }
    
    /// Computes session progress (1.0 = full time remaining, 0.0 = expired)
    private var sessionProgress: Double {
        let totalSeconds = booking.endTime.timeIntervalSince(booking.startTime)
        let remainingSeconds = booking.endTime.timeIntervalSinceNow
        
        guard totalSeconds > 0 else { return 0 }
        
        let progress = remainingSeconds / totalSeconds
        return max(0, min(1, progress))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // === SECTION 1: Status Header ===
            statusHeader
                .padding(.bottom, GFSpacing.lg)
            
            // === SECTION 2: Timer & Progress Ring (Hero) ===
            timerSection
                .padding(.bottom, GFSpacing.xl)
            
            // === SECTION 3: Gym Info ===
            gymInfoSection
                .padding(.bottom, GFSpacing.xl)
            
            // === SECTION 4: Actions ===
            actionsSection
        }
        .padding(GFSpacing.xxl)
        .background(theme.colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: GFCorners.card + 4)) // Slightly larger radius for hero
        .overlay(
            RoundedRectangle(cornerRadius: GFCorners.card + 4)
                .stroke(theme.colors.primary.opacity(0.15), lineWidth: 1)
        )
        .gfPremiumShadow() // Premium shadow for hero card
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
    
    // MARK: - Status Header
    
    private var statusHeader: some View {
        HStack {
            // Status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(theme.colors.success)
                    .frame(width: 8, height: 8)
                
                Text("Active Session")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.colors.success.opacity(0.12))
            .clipShape(Capsule())
            
            Spacer()
        }
    }
    
    // MARK: - Timer Section (Hero)
    
    private var timerSection: some View {
        HStack(spacing: GFSpacing.xl) {
            // Progress Ring
            GFProgressRing(
                progress: sessionProgress,
                lineWidth: 8,
                size: 100,
                showLabel: false,
                animate: !reduceMotion
            )
            
            // Time Display
            VStack(alignment: .leading, spacing: GFSpacing.xs) {
                Text("Time Remaining")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                if reduceMotion {
                    Text(viewModel.formattedTimeRemaining)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                } else {
                    Text(viewModel.formattedTimeRemaining)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(GFMotion.gentle, value: viewModel.formattedTimeRemaining)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Gym Info Section
    
    private var gymInfoSection: some View {
        VStack(alignment: .leading, spacing: GFSpacing.sm) {
            Text(booking.gymName ?? "Gym")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textTertiary)
                
                Text(booking.gymAddress ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GFSpacing.lg)
        .background(theme.colors.surface2.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: GFCorners.medium))
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: GFSpacing.md) {
            // Primary: View QR Code
            Button(action: onViewQRCode) {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 16, weight: .semibold))
                    Text("View QR Code")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.colors.primary)
                .clipShape(RoundedRectangle(cornerRadius: GFCorners.medium))
            }
            
            // Secondary: Cancel Session
            Button {
                DemoTapLogger.log("Home.ActiveSession.CancelTap")
                showCancelConfirmation = true
            } label: {
                Text("Cancel Session")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }
}
