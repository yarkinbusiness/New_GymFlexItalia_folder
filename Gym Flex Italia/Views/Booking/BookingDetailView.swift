//
//  BookingDetailView.swift
//  Gym Flex Italia
//
//  Booking detail/receipt view with cancel and rebook actions
//

import SwiftUI

/// Booking detail view with QR code placeholder and actions
struct BookingDetailView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    let bookingId: String
    
    @StateObject private var viewModel = BookingHistoryViewModel()
    
    @State private var showCancelConfirmation = false
    @State private var showCopiedAlert = false
    
    private var booking: Booking? {
        viewModel.booking(for: bookingId)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let booking = booking {
                bookingContent(booking)
            } else {
                errorView
            }
        }
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(using: appContainer.bookingHistoryService)
        }
        .alert("Cancel Booking", isPresented: $showCancelConfirmation) {
            Button("Keep Booking", role: .cancel) { }
            Button("Cancel Booking", role: .destructive) {
                Task {
                    await cancelBooking()
                }
            }
        } message: {
            Text("Are you sure you want to cancel this booking? A refund will be processed within 3-5 business days.")
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("Reference code copied to clipboard")
        }
    }
    
    // MARK: - Booking Content
    
    private func bookingContent(_ booking: Booking) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Error/Success Banners
                if let error = viewModel.errorMessage {
                    InlineErrorBanner(
                        message: error,
                        type: .error,
                        onDismiss: { viewModel.clearError() }
                    )
                }
                
                if let success = viewModel.successMessage {
                    InlineErrorBanner(
                        message: success,
                        type: .success,
                        onDismiss: { viewModel.clearSuccess() }
                    )
                }
                
                // Status Header
                statusHeader(booking)
                
                // QR Code Section (for upcoming bookings)
                if booking.isUpcoming {
                    qrCodeSection(booking)
                }
                
                // Gym Details
                gymDetailsCard(booking)
                
                // Booking Details
                bookingDetailsCard(booking)
                
                // Actions
                actionsSection(booking)
            }
            .padding(Spacing.lg)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Status Header
    
    private func statusHeader(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            // Status Icon
            Image(systemName: booking.status.icon)
                .font(.system(size: 48))
                .foregroundColor(statusColor(booking.status))
            
            // Status Text
            Text(booking.status.displayName)
                .font(AppFonts.h3)
                .foregroundColor(statusColor(booking.status))
            
            // Timing Info
            if booking.isUpcoming {
                Text(timeUntilBooking(booking))
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    // MARK: - QR Code Section
    
    private func qrCodeSection(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            Text("Check-in QR Code")
                .font(AppFonts.h5)
                .foregroundColor(.primary)
            
            // Real QR Code
            if let qrImage = QRCodeGenerator.makeCheckInQRImage(for: booking) {
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(Spacing.md)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            } else {
                // Fallback placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.lg)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                        
                        Text("QR Code")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Check-in Code Display
            if let checkInCode = booking.checkinCode {
                VStack(spacing: Spacing.xs) {
                    Text("Check-in Code")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    HStack(spacing: Spacing.sm) {
                        Text(checkInCode)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Button {
                            DemoTapLogger.log("BookingDetail.CopyCheckInCode")
                            UIPasteboard.general.string = checkInCode
                            showCopiedAlert = true
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.brand)
                        }
                    }
                }
            }
            
            Text("Show this code at the gym entrance")
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
            
            // Check In Button
            Button {
                DemoTapLogger.log("BookingDetail.CheckIn")
                router.pushCheckIn(bookingId: booking.id)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check In Now")
                }
                .font(AppFonts.label)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
    }
    
    // MARK: - Gym Details Card
    
    private func gymDetailsCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(AppColors.brand)
                Text("Gym")
                    .font(AppFonts.label)
                    .foregroundColor(.secondary)
            }
            
            Text(booking.gymName ?? "Gym")
                .font(AppFonts.h4)
                .foregroundColor(.primary)
            
            if let address = booking.gymAddress {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                    Text(address)
                        .font(AppFonts.bodySmall)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
    }
    
    // MARK: - Booking Details Card
    
    private func bookingDetailsCard(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            // Date
            detailRow(label: "Date", value: formattedDate(booking.startTime), icon: "calendar")
            
            Divider()
            
            // Time
            detailRow(label: "Time", value: formattedTime(booking.startTime), icon: "clock")
            
            Divider()
            
            // Duration
            detailRow(label: "Duration", value: booking.formattedDuration, icon: "timer")
            
            Divider()
            
            // Price - uses totalPaidCents for accurate total including extensions
            let paidCents = WalletStore.shared.totalPaidCents(for: booking.id)
            let baseCents = Int((booking.totalPrice * 100).rounded())
            let totalString = (paidCents > 0)
                ? PricingCalculator.formatCentsAsEUR(paidCents)
                : String(format: "€%.2f", booking.totalPrice)
            let hasExtensions = paidCents > baseCents && baseCents > 0
            
            VStack(spacing: 0) {
                detailRow(label: "Total", value: totalString, icon: "eurosign.circle")
                
                if hasExtensions {
                    HStack {
                        Spacer()
                        Text("Includes extensions")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.sm)
                }
            }
            
            // Reference Code
            if let code = booking.checkinCode {
                Divider()
                
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "number")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        
                        Text("Reference")
                            .font(AppFonts.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.sm) {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Button {
                            DemoTapLogger.log("BookingDetail.CopyReference")
                            copyToClipboard(code)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.brand)
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.lg)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
    }
    
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.brand)
                    .frame(width: 24)
                
                Text(label)
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Actions Section
    
    private func actionsSection(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.md) {
            // Cancel Button (only for upcoming)
            if booking.canCancel {
                Button {
                    DemoTapLogger.log("BookingDetail.CancelBooking")
                    showCancelConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isCancelling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        } else {
                            Image(systemName: "xmark.circle")
                            Text("Cancel Booking")
                        }
                    }
                    .font(AppFonts.label)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
                .disabled(viewModel.isCancelling)
            }
            
            // Rebook Button
            Button {
                DemoTapLogger.log("BookingDetail.Rebook")
                router.handle(deepLink: .bookSession)
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Book Again")
                }
                .font(AppFonts.label)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(AppGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
            
            // View Gym Button
            if let gymId = booking.gymId as String? {
                Button {
                    DemoTapLogger.log("BookingDetail.ViewGym")
                    router.pushGymDetail(gymId: gymId)
                } label: {
                    HStack {
                        Image(systemName: "dumbbell")
                        Text("View Gym")
                    }
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
            }
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Booking Not Found")
                .font(AppFonts.h4)
                .foregroundColor(.primary)
            
            Text("This booking may have been removed or doesn't exist.")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                router.pop()
            }
            .font(AppFonts.label)
            .foregroundColor(AppColors.brand)
        }
        .padding(Spacing.xl)
    }
    
    // MARK: - Helpers
    
    private func statusColor(_ status: BookingStatus) -> Color {
        switch status {
        case .confirmed:
            return .blue
        case .checkedIn:
            return .green
        case .completed:
            return .gray
        case .cancelled:
            return .red
        case .pending:
            return .orange
        case .noShow:
            return .red
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .long, time: .omitted)
    }
    
    private func formattedTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
    
    private func timeUntilBooking(_ booking: Booking) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Starts \(formatter.localizedString(for: booking.startTime, relativeTo: Date()))"
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showCopiedAlert = true
    }
    
    private func cancelBooking() async {
        let success = await viewModel.cancel(id: bookingId, using: appContainer.bookingHistoryService)
        if success {
            // Stay on the detail page to show the updated status
        }
    }
}

#Preview {
    NavigationStack {
        BookingDetailView(bookingId: "booking_upcoming_001")
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}

