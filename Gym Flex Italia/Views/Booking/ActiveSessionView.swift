//
//  ActiveSessionView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import SwiftUI

/// Active session view displayed after booking
struct ActiveSessionView: View {
    @StateObject private var viewModel: ActiveSessionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showQRCode = false
    
    init(booking: Booking) {
        _viewModel = StateObject(wrappedValue: ActiveSessionViewModel(booking: booking))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                if let booking = viewModel.booking {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Status Badge & Timer
                            statusSection
                            
                            // Gym Information
                            gymInfoSection(booking: booking)
                            
                            // QR Code Button
                            qrCodeButton
                            
                            // Session Details
                            sessionDetailsSection(booking: booking)
                            
                            // Extension Options
                            extensionOptionsSection
                            
                            // Need Assistance
                            assistanceButton
                            
                            // Important Note
                            importantNoteSection
                        }
                        .padding(Spacing.lg)
                    }
                } else {
                    // Fallback for empty state (should not happen given init)
                    VStack {
                        Text("No active session")
                            .font(AppFonts.h3)
                            .foregroundColor(AppColors.textHigh)
                    }
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
            .navigationTitle("Active Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textHigh)
                    }
                }
            }
            .sheet(isPresented: $showQRCode) {
                if let booking = viewModel.booking, let qrCode = booking.qrCodeData {
                    QRCodeDisplayView(qrCodeData: qrCode, booking: booking)
                }
            }
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: Spacing.md) {
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
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(viewModel.isExpired ? AppColors.danger.opacity(0.2) : AppColors.success.opacity(0.2))
            )
            
            // Timer
            Text(viewModel.formattedTimeRemaining)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.isExpired ? AppColors.danger : AppColors.textHigh)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassBackground(cornerRadius: CornerRadii.xl, opacity: 0.4, blur: 25)
    }
    
    // MARK: - Gym Info Section
    private func gymInfoSection(booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(booking.gymName ?? "Gym")
                .font(AppFonts.h3)
                .foregroundColor(AppColors.textHigh)
            
            Button {
                viewModel.openMapsDirections()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.brand)
                    
                    Text(booking.gymAddress ?? "")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textMedium)
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
        .glassBackground(cornerRadius: CornerRadii.lg, opacity: 0.3, blur: 18)
    }
    
    // MARK: - QR Code Button
    private var qrCodeButton: some View {
        Button {
            showQRCode = true
        } label: {
            HStack {
                Image(systemName: "qrcode")
                    .font(.system(size: 20))
                
                Text("View QR Code")
                    .font(AppFonts.label)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding(Spacing.lg)
            .background(AppGradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg, style: .continuous))
            .shadow(color: AppColors.brand.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Session Details Section
    private func sessionDetailsSection(booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Session Details")
                    .font(AppFonts.h5)
                    .foregroundColor(AppColors.textHigh)
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
                
                DetailRow(
                    label: "Session ID",
                    value: String(booking.id.suffix(8))
                )
            }
        }
        .padding(Spacing.lg)
        .glassBackground(cornerRadius: CornerRadii.lg, opacity: 0.3, blur: 18)
    }
    
    // MARK: - Extension Options Section
    private var extensionOptionsSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("Extend Session")
                    .font(AppFonts.h5)
                    .foregroundColor(AppColors.textHigh)
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
        .glassBackground(cornerRadius: CornerRadii.lg, opacity: 0.3, blur: 18)
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
            .foregroundColor(AppColors.textHigh)
            .padding(Spacing.lg)
            .glassBackground(cornerRadius: CornerRadii.lg, opacity: 0.3, blur: 18)
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
            
            Text("Keep your screen brightness high when scanning the QR code at the gym entrance. Your QR code is unique to this session and cannot be shared.")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textDim)
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
                .foregroundColor(AppColors.textHigh)
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
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.label)
                .foregroundColor(AppColors.textHigh)
        }
    }
}

// MARK: - Extension Button
struct ExtensionButton: View {
    let minutes: Int
    let price: Double
    let isExtending: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text("+\(minutes) min")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                
                Text("€\(String(format: "%.2f", price))")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if isExtending {
                        AppColors.secondary
                    } else {
                        AppGradients.primary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))
            .shadow(
                color: isExtending ? Color.clear : AppColors.brand.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isExtending)
    }
}

// MARK: - QR Code Display View
struct QRCodeDisplayView: View {
    let qrCodeData: String
    let booking: Booking
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppGradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    Spacer()
                    
                    // QR Code
                    if let qrImage = generateQRCode(from: qrCodeData) {
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
                    
                    VStack(spacing: Spacing.sm) {
                        Text(booking.gymName ?? "")
                            .font(AppFonts.h4)
                            .foregroundColor(AppColors.textHigh)
                        
                        Text("Session ID: \(String(booking.id.suffix(8)))")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textDim)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Check-in QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.textHigh)
                    }
                }
            }
        }
    }
    
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
    ActiveSessionView(booking: MockData.sampleBookings[0])
}
