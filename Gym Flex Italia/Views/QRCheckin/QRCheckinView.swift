//
//  QRCheckinView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// QR check-in view showing full active session details
struct QRCheckinView: View {
    
    let bookingId: String
    @StateObject private var viewModel: ActiveSessionViewModel
    @State private var showSessionSummary = false
    @State private var isLoading = true
    @Environment(\.appContainer) var appContainer
    
    // Initialize with a booking ID (optional) or fetch active
    init(bookingId: String = "") {
        self.bookingId = bookingId
        // Initialize with nil booking (empty state)
        _viewModel = StateObject(wrappedValue: ActiveSessionViewModel(booking: nil))
    }
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if isLoading {
                LoadingOverlayView()
            } else if let booking = viewModel.booking {
                if viewModel.isExpired {
                    // Finished session state
                    finishedSessionView(booking: booking)
                } else {
                    // Active session state
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Status Badge & Timer
                            statusSection
                            
                            // Gym Information
                            gymInfoSection(booking: booking)
                            
                            // Main QR Code Display
                            mainQRCodeSection(booking: booking)
                            
                            // Session Details
                            sessionDetailsSection(booking: booking)
                            
                            // Extension Options
                            extensionOptionsSection(booking: booking)
                            
                            // Need Assistance
                            assistanceButton
                            
                            // Important Note
                            importantNoteSection
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                    .refreshable {
                        await loadActiveBooking()
                    }
                }
            } else {
                emptyStateView
            }
            
            // Insufficient Funds Toast
            if viewModel.showInsufficientFunds {
                VStack {
                    HStack {
                        Spacer()
                        insufficientFundsToast
                            .padding(.trailing, Spacing.lg)
                    }
                    Spacer()
                }
                .padding(.top, Spacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showInsufficientFunds)
            }
        }
        .task {
            viewModel.configure(checkInService: appContainer.checkInService)
            await loadActiveBooking()
        }
    }
    
    private func loadActiveBooking() async {
        isLoading = true
        defer { isLoading = false }
        
        // PRIORITY 1: Check BookingManager for freshly created bookings
        if let managerBooking = BookingManager.shared.activeBooking {
            print("✅ QRCheckinView: Using booking from BookingManager")
            updateViewModel(with: managerBooking)
            return
        }
        
        // PRIORITY 2: If we have a specific booking ID, try to load that
        if !bookingId.isEmpty {
            if let booking = try? await appContainer.bookingHistoryService.fetchBooking(id: bookingId) {
                updateViewModel(with: booking)
                return
            }
        }
        
        // PRIORITY 3: Find active OR most recent completed booking
        if let bookings = try? await appContainer.bookingHistoryService.fetchBookings() {
            // First, look for active
            var targetBooking = bookings.first { $0.status == .checkedIn || $0.status == .confirmed }
            
            // If no active, look for most recent completed
            if targetBooking == nil {
                targetBooking = bookings
                    .filter { $0.status == .completed }
                    .sorted { $0.endTime > $1.endTime }
                    .first
            }
            
            // Update with found booking or nil if none found
            updateViewModel(with: targetBooking)
        } else {
            // No active booking found or error
            updateViewModel(with: nil)
        }
    }
    
    private func updateViewModel(with booking: Booking?) {
        viewModel.update(booking: booking)
    }
    
    // MARK: - Finished Session State
    private func finishedSessionView(booking: Booking) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Finished Badge
                VStack(spacing: Spacing.md) {
                    Circle()
                        .fill(AppColors.danger)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(AppColors.danger.opacity(0.3), lineWidth: 16)
                        )
                    
                    Text("SESSION FINISHED")
                        .font(AppFonts.label)
                        .foregroundColor(AppColors.danger)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text("Your workout session has ended")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xl)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.xl)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // Previous Session Details
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Session Summary")
                        .font(AppFonts.h5)
                        .foregroundColor(Color(.label))
                    
                    VStack(spacing: Spacing.sm) {
                        DetailRow(
                            label: "Gym",
                            value: booking.gymName ?? "N/A"
                        )
                        
                        DetailRow(
                            label: "Duration",
                            value: "\(booking.duration) minutes"
                        )
                        
                        DetailRow(
                            label: "Total Cost",
                            value: "€\(String(format: "%.2f", booking.totalPrice))"
                        )
                        
                        DetailRow(
                            label: "Ended",
                            value: booking.endTime.formatted(date: .omitted, time: .shortened)
                        )
                    }
                }
                .padding(Spacing.lg)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.lg)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // Book Again Button
                Button {
                    TabManager.shared.switchTo(.discover)
                } label: {
                    Text("Book Another Session")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
            }
            .padding(Spacing.lg)
            .padding(.bottom, 100)
        }
        .refreshable {
            await loadActiveBooking()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(Color(.secondaryLabel))
            
            VStack(spacing: Spacing.sm) {
                Text("No Active Session")
                    .font(AppFonts.h2)
                    .foregroundColor(Color(.label))
                
                Text("Book a gym session to see your pass here")
                    .font(AppFonts.body)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                TabManager.shared.switchTo(.discover)
            } label: {
                Text("Find Gyms")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.xxl)
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        GFCard(padding: GFSpacing.xl) {
            VStack(spacing: GFSpacing.md) {
                // Status Badge
                HStack {
                    Circle()
                        .fill(viewModel.isExpired ? AppColors.danger : AppColors.success)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isExpired ? "Session Expired" : "Active Session")
                        .font(AppFonts.label)
                        .foregroundColor(viewModel.isExpired ? AppColors.danger : AppColors.success)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .padding(.horizontal, GFSpacing.md)
                .padding(.vertical, GFSpacing.sm)
                .background(
                    Capsule()
                        .fill(viewModel.isExpired ? AppColors.danger.opacity(0.2) : AppColors.success.opacity(0.2))
                )
                
                // Timer
                Text(viewModel.formattedTimeRemaining)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.isExpired ? AppColors.danger : Color(.label))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Gym Info Section
    private func gymInfoSection(booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(booking.gymName ?? "Gym")
                .font(AppFonts.h3)
                .foregroundColor(Color(.label))
            
            Button {
                viewModel.openMapsDirections()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.brand)
                    
                    Text(booking.gymAddress ?? "")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.secondaryLabel))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.brand)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Main QR Code Section
    private func mainQRCodeSection(booking: Booking) -> some View {
        VStack(spacing: Spacing.lg) {
            if let qrCode = booking.qrCodeData,
               let qrImage = generateQRCode(from: qrCode) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(Spacing.lg)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.xl))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: Spacing.xs) {
                Text("Session ID")
                    .font(AppFonts.caption)
                    .foregroundColor(Color(.secondaryLabel))
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(String(booking.id.suffix(8)))
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                    .monospaced()
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.xl)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Session Details Section
    private func sessionDetailsSection(booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Session Details")
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                Spacer()
            }
            
            VStack(spacing: Spacing.sm) {
                DetailRow(
                    label: "Duration",
                    value: "\(booking.duration) minutes"
                )
                
                DetailRow(
                    label: "Total Cost",
                    value: "€\(String(format: "%.2f", booking.totalPrice))"
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Extension Options Section
    private func extensionOptionsSection(booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Extend Session")
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                Spacer()
            }
            
            HStack(spacing: Spacing.sm) {
                ExtensionButton(
                    minutes: 30,
                    price: viewModel.extensionPrice(minutes: 30),
                    isExtending: viewModel.isExtending
                ) {
                    Task {
                        await viewModel.extendSession(additionalMinutes: 30)
                    }
                }
                
                ExtensionButton(
                    minutes: 60,
                    price: viewModel.extensionPrice(minutes: 60),
                    isExtending: viewModel.isExtending
                ) {
                    Task {
                        await viewModel.extendSession(additionalMinutes: 60)
                    }
                }
                
                ExtensionButton(
                    minutes: 120,
                    price: viewModel.extensionPrice(minutes: 120),
                    isExtending: viewModel.isExtending
                ) {
                    Task {
                        await viewModel.extendSession(additionalMinutes: 120)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Assistance Button
    private var assistanceButton: some View {
        Button {
            // TODO: Implement assistance flow
        } label: {
            HStack {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                
                Text("Need Assistance")
                    .font(AppFonts.label)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(Color(.label))
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.lg)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Important Note Section
    private var importantNoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.warning)
                
                Text("Important")
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.warning)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            Text("Please show this QR code to the staff at the gym entrance. Keep your phone screen brightness high for better scanning. Code auto-refreshes every 60 seconds for security.")
                .font(AppFonts.bodySmall)
                .foregroundColor(Color(.secondaryLabel))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColors.warning.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadii.md)
                .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
    }
    
    // MARK: - Insufficient Funds Toast
    private var insufficientFundsToast: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)
            
            Text("Insufficient Balance")
                .font(AppFonts.label)
                .foregroundColor(Color(.label))
        }
        .padding(Spacing.md)
        .background(AppColors.danger.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadii.md)
                .stroke(AppColors.danger, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper Methods
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCheckinView()
}
