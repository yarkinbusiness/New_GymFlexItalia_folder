//
//  CheckInHomeView.swift
//  Gym Flex Italia
//
//  Main check-in tab view showing next upcoming booking with QR code
//

import SwiftUI
import Combine

/// Check-in tab home view displaying upcoming bookings with QR codes
struct CheckInHomeView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    @StateObject private var viewModel = BookingHistoryViewModel()
    
    /// Timer for countdown updates
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingOverlayView(message: "Loading bookings...")
            } else {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Debug Banner (DEBUG builds only)
                        #if DEBUG
                        debugBanner
                        #endif
                        
                        // Error Banner
                        if let error = viewModel.errorMessage {
                            InlineErrorBanner(
                                message: error,
                                type: .error,
                                onDismiss: { viewModel.clearError() }
                            )
                        }
                        
                        // Next Check-in Section
                        if let nextBooking = viewModel.upcomingBookings.first {
                            nextCheckInSection(nextBooking)
                        } else {
                            emptyStateView
                        }
                        
                        // Upcoming Bookings List
                        if viewModel.upcomingBookings.count > 1 {
                            upcomingBookingsSection
                        }
                    }
                    .padding(Spacing.lg)
                    .padding(.bottom, 100) // Space for tab bar
                }
                .refreshable {
                    await loadBookings()
                }
            }
        }
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadBookings()
        }
        .onAppear {
            print("👀 CheckInHomeView.onAppear: Reloading bookings...")
            Task {
                await loadBookings()
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
    
    /// Load bookings from service and sync with store
    private func loadBookings() async {
        // Ensure store is seeded
        MockBookingStore.shared.seedIfNeeded()
        
        print("🔄 CheckInHomeView: Loading bookings...")
        print("📊 CheckInHomeView: Store state before load:\n\(MockBookingStore.shared.debugDump())")
        
        await viewModel.load(using: appContainer.bookingHistoryService)
        
        print("✅ CheckInHomeView: Loaded \(viewModel.upcomingBookings.count) upcoming bookings")
    }
    
    // MARK: - Debug Banner
    
    #if DEBUG
    private var debugBanner: some View {
        VStack(spacing: Spacing.xs) {
            Text("DEBUG: Upcoming: \(viewModel.upcomingBookings.count) | Store: \(MockBookingStore.shared.upcomingBookings().count)")
                .font(AppFonts.caption)
                .foregroundColor(.orange)
        }
    }
    #endif
    
    // MARK: - Next Check-in Section
    
    private func nextCheckInSection(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.lg) {
            // Section Header
            HStack {
                Text("Next Check-in")
                    .font(AppFonts.h4)
                    .foregroundColor(.primary)
                
                Spacer()
                
                statusBadge(booking)
            }
            
            // Countdown Timer
            countdownSection(booking)
            
            // QR Card
            qrCodeCard(booking)
            
            // Booking Details Card
            bookingDetailsCard(booking)
            
            // Check In Button
            checkInButton(booking)
        }
    }
    
    // MARK: - Countdown Section
    
    private func countdownSection(_ booking: Booking) -> some View {
        let remaining = booking.endTime.timeIntervalSince(now)
        let isEnded = remaining <= 0
        
        return VStack(spacing: Spacing.xs) {
            if isEnded {
                Text("Session Ended")
                    .font(AppFonts.h3)
                    .foregroundColor(.secondary)
            } else {
                Text("Time Remaining")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(formatCountdown(remaining))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(remaining < 300 ? .orange : AppColors.brand)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadii.lg)
                .fill(isEnded ? Color.gray.opacity(0.1) : AppColors.brand.opacity(0.1))
        )
    }
    
    /// Format remaining seconds as HH:MM:SS
    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    // MARK: - QR Code Card
    
    private func qrCodeCard(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.lg) {
            // QR Code
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
                // Fallback QR placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.lg)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 200, height: 200)
                    
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("QR Code")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Check-in Code
            VStack(spacing: Spacing.xs) {
                Text("Check-in Code")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                HStack(spacing: Spacing.sm) {
                    Text(booking.checkinCode ?? "—")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Button {
                        DemoTapLogger.log("CheckInHome.CopyCode")
                        if let code = booking.checkinCode {
                            UIPasteboard.general.string = code
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.brand)
                    }
                }
            }
            
            Text("Show this code at the gym entrance")
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.xl))
    }
    
    // MARK: - Booking Details Card
    
    private func bookingDetailsCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Gym Name
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(AppColors.brand)
                    .font(.system(size: 16))
                
                Text(booking.gymName ?? "Gym")
                    .font(AppFonts.h5)
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            // Date & Time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    Text(booking.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    Text(booking.startTime.formatted(date: .omitted, time: .shortened))
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
            
            // Duration & Price
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    Text(booking.formattedDuration)
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "€%.2f", booking.totalPrice))
                        .font(AppFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
    }
    
    // MARK: - Check In Button
    
    private func checkInButton(_ booking: Booking) -> some View {
        Button {
            DemoTapLogger.log("CheckInHome.CheckInNow")
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
    
    // MARK: - Status Badge
    
    private func statusBadge(_ booking: Booking) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppColors.success)
                .frame(width: 8, height: 8)
            
            Text(timeUntilBooking(booking))
                .font(AppFonts.caption)
                .foregroundColor(AppColors.success)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.success.opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Upcoming Bookings Section
    
    private var upcomingBookingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Upcoming")
                .font(AppFonts.h5)
                .foregroundColor(.primary)
            
            ForEach(viewModel.upcomingBookings.dropFirst()) { booking in
                upcomingBookingRow(booking)
            }
        }
    }
    
    private func upcomingBookingRow(_ booking: Booking) -> some View {
        Button {
            DemoTapLogger.log("CheckInHome.ViewBooking")
            router.pushBookingDetail(bookingId: booking.id)
        } label: {
            HStack(spacing: Spacing.md) {
                // Gym Icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.brand)
                    .frame(width: 44, height: 44)
                    .background(AppColors.brand.opacity(0.15))
                    .clipShape(Circle())
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.gymName ?? "Gym")
                        .font(AppFonts.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(booking.startTime.formatted(date: .abbreviated, time: .shortened)) • \(booking.formattedDuration)")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.sm) {
                Text("No Upcoming Bookings")
                    .font(AppFonts.h3)
                    .foregroundColor(.primary)
                
                Text("Book a gym session to get your check-in QR code")
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                DemoTapLogger.log("CheckInHome.FindGyms")
                router.handle(deepLink: .bookSession)
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Find Gyms")
                }
                .font(AppFonts.label)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(AppGradients.primary)
                .clipShape(Capsule())
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func timeUntilBooking(_ booking: Booking) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: booking.startTime, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        CheckInHomeView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
