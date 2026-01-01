//
//  CheckInHomeView.swift
//  Gym Flex Italia
//
//  Main check-in tab view showing the current user session with QR code.
//
//  IMPORTANT: Uses MockBookingStore.currentUserSession() for session detection.
//  This ensures Home and Check-in tabs show the SAME booking.
//

import SwiftUI
import Combine

/// Check-in tab home view displaying current user session with QR code
struct CheckInHomeView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    /// The current user session (from shared store logic)
    @State private var currentSession: Booking?
    
    /// Additional upcoming user bookings (excluding current session)
    @State private var upcomingUserBookings: [Booking] = []
    
    /// Loading state
    @State private var isLoading = false
    
    /// Extension in progress (prevent double taps)
    @State private var isExtending = false
    
    /// Error message
    @State private var errorMessage: String?
    
    /// Success message for extension
    @State private var successMessage: String?
    
    /// Timer for countdown updates
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if isLoading {
                LoadingOverlayView(message: "Loading session...")
            } else {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Debug Banner (DEBUG builds only)
                        #if DEBUG
                        debugBanner
                        #endif
                        
                        // Error Banner
                        if let error = errorMessage {
                            InlineErrorBanner(
                                message: error,
                                type: .error,
                                onDismiss: { errorMessage = nil }
                            )
                        }
                        
                        // Success Banner
                        if let success = successMessage {
                            InlineErrorBanner(
                                message: success,
                                type: .success,
                                onDismiss: { successMessage = nil }
                            )
                        }
                        
                        // Current Session Section (using shared currentUserSession)
                        if let session = currentSession {
                            currentSessionSection(session)
                        } else {
                            emptyStateView
                        }
                        
                        // Additional Upcoming User Bookings
                        if !upcomingUserBookings.isEmpty {
                            upcomingBookingsSection
                        }
                    }
                    .padding(Spacing.lg)
                    .padding(.bottom, 100) // Space for tab bar
                }
                .refreshable {
                    await loadSession()
                }
            }
        }
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadSession()
        }
        .onAppear {
            print("👀 CheckInHomeView.onAppear: Reloading session...")
            Task {
                await loadSession()
            }
        }
        .onReceive(timer) { _ in
            now = Date()
            
            // Check if session has ended
            if let session = currentSession, session.endTime <= now {
                print("⏰ CheckInHomeView: Session ended, reloading...")
                Task {
                    await loadSession()
                }
            }
        }
    }
    
    /// Load current session using SHARED currentUserSession() logic
    private func loadSession() async {
        // Ensure store is seeded
        MockBookingStore.shared.seedIfNeeded()
        
        print("🔄 CheckInHomeView: Loading session using currentUserSession()...")
        print("📊 CheckInHomeView: Store state:\n\(MockBookingStore.shared.debugDump())")
        
        // IMPORTANT: Use the SAME shared selection logic as HomeViewModel
        currentSession = MockBookingStore.shared.currentUserSession()
        
        // Get additional upcoming user bookings (excluding the current session)
        let allUpcoming = MockBookingStore.shared.upcomingUserBookings()
        if let current = currentSession {
            upcomingUserBookings = allUpcoming.filter { $0.id != current.id }
        } else {
            upcomingUserBookings = allUpcoming
        }
        
        print("✅ CheckInHomeView: currentSession=\(currentSession?.id ?? "nil"), upcomingUserBookings=\(upcomingUserBookings.count)")
    }
    
    // MARK: - Debug Banner
    
    #if DEBUG
    private var debugBanner: some View {
        VStack(spacing: Spacing.xs) {
            Text("DEBUG: Session=\(currentSession?.id ?? "nil")")
                .font(AppFonts.caption)
                .foregroundColor(.orange)
            
            Text("UserBookings: \(MockBookingStore.shared.userBookings().count) | All: \(MockBookingStore.shared.bookings.count)")
                .font(AppFonts.caption)
                .foregroundColor(.orange)
        }
    }
    #endif
    
    // MARK: - Current Session Section
    
    private func currentSessionSection(_ booking: Booking) -> some View {
        VStack(spacing: Spacing.lg) {
            // Section Header
            HStack {
                Text("Current Session")
                    .font(AppFonts.h4)
                    .foregroundColor(.primary)
                
                Spacer()
                
                statusBadge(booking)
            }
            
            // Countdown Timer
            countdownSection(booking)
            
            // Extend Time Buttons (only when session is active)
            if booking.endTime > now {
                extendTimeSection(booking)
            }
            
            // QR Card (QR code is ONLY shown here on Check-in tab)
            qrCodeCard(booking)
            
            // Booking Details Card
            bookingDetailsCard(booking)
            
            // Check In Button (for manual check-in)
            if booking.status == .confirmed {
                checkInButton(booking)
            }
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
    
    // MARK: - Extend Time Section
    
    private func extendTimeSection(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Extend Time")
                .font(AppFonts.h5)
                .foregroundColor(.primary)
            
            HStack(spacing: Spacing.sm) {
                ExtendTimeButton(
                    minutes: 30,
                    price: "€1",
                    isDisabled: isExtending
                ) {
                    await handleExtend(booking: booking, minutes: 30, costCents: 100)
                }
                
                ExtendTimeButton(
                    minutes: 60,
                    price: "€2",
                    isDisabled: isExtending
                ) {
                    await handleExtend(booking: booking, minutes: 60, costCents: 200)
                }
                
                ExtendTimeButton(
                    minutes: 90,
                    price: "€3",
                    isDisabled: isExtending
                ) {
                    await handleExtend(booking: booking, minutes: 90, costCents: 300)
                }
            }
            
            if isExtending {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Extending session...")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg))
    }
    
    /// Handle extend time button tap
    private func handleExtend(booking: Booking, minutes: Int, costCents: Int) async {
        guard !isExtending else { return }
        
        isExtending = true
        errorMessage = nil
        successMessage = nil
        
        DemoTapLogger.log("CheckIn.Extend.\(minutes)min")
        
        do {
            // Check wallet balance
            let walletStore = WalletStore.shared
            guard walletStore.balanceCents >= costCents else {
                throw BookingExtensionError.insufficientFunds
            }
            
            // Debit wallet (use extension as booking ref suffix)
            try walletStore.applyDebitForBooking(
                amountCents: costCents,
                bookingRef: "\(booking.id)-ext",
                gymName: booking.gymName ?? "Gym",
                gymId: booking.gymId
            )
            
            // Extend booking in store
            let updatedBooking = try MockBookingStore.shared.extend(
                bookingId: booking.id,
                addMinutes: minutes
            )
            
            // Update current session
            currentSession = updatedBooking
            
            successMessage = "+\(minutes) minutes added! New end time: \(updatedBooking.endTime.formatted(date: .omitted, time: .shortened))"
            
            print("✅ CheckInHomeView: Extended booking by \(minutes)min, new duration=\(updatedBooking.duration)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ CheckInHomeView: Extension failed - \(error.localizedDescription)")
        }
        
        isExtending = false
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
        let remaining = booking.endTime.timeIntervalSince(now)
        let isEnded = remaining <= 0
        
        return HStack(spacing: 4) {
            Circle()
                .fill(isEnded ? Color.gray : AppColors.success)
                .frame(width: 8, height: 8)
            
            Text(isEnded ? "Ended" : (booking.status == .checkedIn ? "Active" : timeUntilBooking(booking)))
                .font(AppFonts.caption)
                .foregroundColor(isEnded ? .gray : AppColors.success)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background((isEnded ? Color.gray : AppColors.success).opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Upcoming Bookings Section
    
    private var upcomingBookingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Upcoming")
                .font(AppFonts.h5)
                .foregroundColor(.primary)
            
            ForEach(upcomingUserBookings) { booking in
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
                Text("No Active Session")
                    .font(AppFonts.h3)
                    .foregroundColor(.primary)
                
                Text("Book a gym session to get your check-in QR code")
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                DemoTapLogger.log("CheckInHome.FindGyms")
                router.switchToTab(.discover)
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

// MARK: - Extend Time Button

struct ExtendTimeButton: View {
    let minutes: Int
    let price: String
    let isDisabled: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            VStack(spacing: 4) {
                Text("+\(minutes)")
                    .font(AppFonts.h5)
                    .foregroundColor(isDisabled ? .secondary : AppColors.brand)
                
                Text("min")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                
                Text(price)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(isDisabled ? .secondary : AppColors.success)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isDisabled ? Color.gray.opacity(0.1) : AppColors.brand.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.md)
                    .stroke(isDisabled ? Color.gray.opacity(0.3) : AppColors.brand.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        CheckInHomeView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
