//
//  DashboardView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//
//  Home tab - uses HomeViewModel with canonical data stores.
//  No placeholder data - only real data from MockBookingStore and MockDataStore.
//

import SwiftUI
import CoreLocation

/// Main dashboard/home view using canonical data stores
struct DashboardView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var locationService: LocationService
    @Environment(\.appContainer) var appContainer
    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.gfTheme) private var theme
    
    var body: some View {
        ZStack {
            // Layered background (surface0 = deepest layer)
            theme.colors.surface0
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: GFSpacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Active Session or Quick Book Section
                    if let activeBooking = viewModel.activeBooking {
                        ActiveSessionSummaryCard(
                            booking: activeBooking,
                            onViewQRCode: {
                                // Switch to Check-in tab
                                DemoTapLogger.log("Dashboard.ActiveSession.ViewQR")
                                router.switchToTab(.checkIn)
                            },
                            onCancel: {
                                // Cancel the active session (no refund)
                                viewModel.cancelActiveSession()
                            }
                        )
                    } else {
                        quickBookSection
                    }
                    
                    // Nearby Gyms Section
                    nearbyGymsSection
                    
                    // Recent Activity Section
                    recentActivitySection
                }
                .padding(.horizontal, GFSpacing.lg)
                .padding(.top, GFSpacing.lg)
                .padding(.bottom, 100) // Space for tab bar
            }
            .refreshable {
                viewModel.load()
                locationService.startIfAuthorized()
                viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
            }
            
            if viewModel.isLoading {
                LoadingOverlayView()
            }
        }
        .task {
            viewModel.load()
            // Try to start location if already authorized (first-time or returning user)
            locationService.startIfAuthorized()
            viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            viewModel.refreshNearbyGyms(userLocation: newLocation)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // When app returns from Settings, refresh location permission
            if newPhase == .active {
                #if DEBUG
                print("📍 DashboardView: App became active, refreshing location...")
                #endif
                locationService.startIfAuthorized()
                viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
            }
        }
        .alert("Booking Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back")
                        .font(AppFonts.h1)
                        .foregroundColor(Color(.label))
                    
                    Text("Ready to crush your goals?")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                // Wallet Button
                WalletButtonView {
                    DemoTapLogger.log("Dashboard.Wallet")
                    router.pushWallet()
                }
                
                // Settings Button
                Button {
                    DemoTapLogger.log("Dashboard.Settings")
                    router.pushSettings()
                } label: {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(.label))
                        .frame(width: 44, height: 44)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(CornerRadii.md)
                }
            }
        }
    }
    
    // MARK: - Quick Book Section
    private var quickBookSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Book")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
                
                Text("Start your workout instantly")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            // Get last booking summary from view model
            let summary = viewModel.lastBookingSummary()
            
            if summary != nil || viewModel.lastUserBooking != nil {
                // Show Quick Book cards with last booking info
                VStack(spacing: Spacing.sm) {
                    QuickBookCard(
                        duration: "1 Hour",
                        price: "€2",
                        isSelected: true,
                        lastGym: summary?.gymName,
                        lastDate: summary?.relativeDate ?? "",
                        lastPrice: summary?.priceString ?? ""
                    ) {
                        handleQuickBook(duration: 60)
                    }
                    
                    QuickBookCard(
                        duration: "1.5 Hours",
                        price: "€3",
                        isSelected: false,
                        lastGym: summary?.gymName,
                        lastDate: summary?.relativeDate ?? "",
                        lastPrice: summary?.priceString ?? ""
                    ) {
                        handleQuickBook(duration: 90)
                    }
                    
                    QuickBookCard(
                        duration: "2 Hours",
                        price: "€4",
                        isSelected: false,
                        lastGym: summary?.gymName,
                        lastDate: summary?.relativeDate ?? "",
                        lastPrice: summary?.priceString ?? ""
                    ) {
                        handleQuickBook(duration: 120)
                    }
                }
            } else {
                // Empty state - no bookings yet
                emptyQuickBookState
            }
        }
    }
    
    /// Empty state for Quick Book when no bookings exist
    private var emptyQuickBookState: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textDim)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("No recent bookings yet")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    Text("Book your first session to get started")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
            }
            
            Button {
                DemoTapLogger.log("Dashboard.FindGyms")
                router.switchToTab(.discover)
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Find Gyms")
                }
                .font(AppFonts.label)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppGradients.primary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
    }
    
    /// Handle Quick Book action
    private func handleQuickBook(duration: Int) {
        Task {
            DemoTapLogger.log("Dashboard.QuickBook\(duration)min")
            
            // If we have a last booking, book at the same gym
            if let lastBooking = viewModel.lastUserBooking {
                do {
                    let _ = try await appContainer.bookingService.createBooking(
                        gymId: lastBooking.gymId,
                        date: Date(),
                        duration: duration
                    )
                    // Refresh data and navigate to Check-in
                    viewModel.load()
                    router.switchToTab(.checkIn)
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            } else {
                // No last booking - navigate to Discover
                router.switchToTab(.discover)
            }
        }
    }
    
    // MARK: - Nearby Gyms Section
    private var nearbyGymsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Nearby Gyms")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Button("See All") {
                    DemoTapLogger.log("Dashboard.SeeAllGyms")
                    router.switchToTab(.discover)
                }
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.brand)
            }
            
            // Location permission banner if needed
            if !viewModel.locationPermissionGranted && locationService.authorizationStatus != .authorizedWhenInUse && locationService.authorizationStatus != .authorizedAlways {
                locationBanner
            }
            
            VStack(spacing: Spacing.sm) {
                if !viewModel.nearbyGyms.isEmpty {
                    ForEach(viewModel.nearbyGyms) { gym in
                        NearbyGymCardWithDistance(
                            gym: gym,
                            distance: viewModel.distanceString(for: gym, from: locationService.currentLocation)
                        ) {
                            DemoTapLogger.log("Dashboard.GymCard.\(gym.id)")
                            router.pushGymDetail(gymId: gym.id)
                        }
                    }
                } else {
                    // Empty state for nearby gyms
                    emptyNearbyGymsState
                }
            }
        }
    }
    
    /// Location permission banner
    private var locationBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "location.slash.fill")
                .foregroundColor(AppColors.warning)
            
            Text("Enable location to see nearest gyms")
                .font(AppFonts.bodySmall)
                .foregroundColor(Color(.secondaryLabel))
            
            Spacer()
            
            Button(locationButtonLabel) {
                locationService.handleEnableLocationTapped()
            }
            .font(AppFonts.caption)
            .foregroundColor(AppColors.brand)
        }
        .padding(Spacing.sm)
        .background(AppColors.warning.opacity(0.1))
        .cornerRadius(CornerRadii.sm)
    }
    
    /// Dynamic button label based on permission status
    private var locationButtonLabel: String {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            return "Open Settings"
        case .notDetermined:
            return "Enable Location"
        default:
            // Banner hidden when authorized; empty fallback for safety
            return ""
        }
    }
    
    /// Empty state for nearby gyms
    private var emptyNearbyGymsState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textDim)
            
            Text("No gyms found")
                .font(AppFonts.body)
                .foregroundColor(Color(.label))
            
            Button {
                router.switchToTab(.discover)
            } label: {
                Text("Browse All Gyms")
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Button("See All") {
                    DemoTapLogger.log("Dashboard.SeeAllActivity")
                    router.pushBookingHistory()
                }
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.brand)
            }
            
            let activityItems = viewModel.recentActivityItems()
            
            VStack(spacing: Spacing.sm) {
                if !activityItems.isEmpty {
                    ForEach(activityItems) { item in
                        RecentActivityCard(
                            booking: item.booking,
                            isOngoing: item.isOngoing
                        )
                    }
                } else {
                    // Empty state
                    emptyRecentActivityState
                }
            }
        }
    }
    
    /// Empty state for recent activity
    private var emptyRecentActivityState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textDim)
            
            Text("Your recent activity will appear here.")
                .font(AppFonts.body)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
            
            Button {
                router.switchToTab(.discover)
            } label: {
                Text("Book a Session")
                    .font(AppFonts.label)
                    .foregroundColor(AppColors.brand)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
    }
}

// MARK: - Nearby Gym Card with Distance
struct NearbyGymCardWithDistance: View {
    let gym: Gym
    let distance: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(gym.name)
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.textHigh)
                    
                    HStack(spacing: 4) {
                        Text(gym.address)
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textDim)
                            .lineLimit(1)
                        
                        if let distance = distance {
                            Text("• \(distance)")
                                .font(AppFonts.bodySmall)
                                .foregroundColor(AppColors.brand)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(String(format: "€%.0f/h", gym.pricePerHour))
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.brand)
                    
                    if let rating = gym.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.warning)
                            Text(String(format: "%.1f", rating))
                                .font(AppFonts.bodySmall)
                                .foregroundColor(AppColors.textHigh)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Card
struct RecentActivityCard: View {
    let booking: Booking
    let isOngoing: Bool
    
    init(booking: Booking, isOngoing: Bool = false) {
        self.booking = booking
        self.isOngoing = isOngoing
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(booking.gymName ?? "Gym")
                        .font(isOngoing ? AppFonts.h5.weight(.bold) : AppFonts.h5)
                        .foregroundColor(Color(.label))
                    
                    // Ongoing indicator dot
                    if isOngoing {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(formattedDate)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedPrice)
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                
                statusBadge
            }
        }
        .padding(Spacing.md)
        .background(isOngoing ? AppColors.success.opacity(0.08) : Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadii.md)
                .stroke(isOngoing ? AppColors.success.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var formattedDate: String {
        if isOngoing {
            return "Now"
        }
        let calendar = Calendar.current
        if calendar.isDateInToday(booking.startTime) {
            return "Today"
        } else if calendar.isDateInYesterday(booking.startTime) {
            return "Yesterday"
        } else {
            return booking.startTime.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private var formattedPrice: String {
        if booking.totalPrice > 0 {
            return String(format: "€%.2f", booking.totalPrice)
        }
        // Fallback calculation
        let totalCents = PricingCalculator.priceForBooking(durationMinutes: booking.duration, gymPricePerHour: booking.pricePerHour)
        return PricingCalculator.formatCentsAsEUR(totalCents)
    }
    
    private var statusBadge: some View {
        Text(isOngoing ? "Ongoing" : booking.status.displayName)
            .font(AppFonts.caption)
            .fontWeight(isOngoing ? .semibold : .regular)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
    }
    
    private var statusColor: Color {
        if isOngoing {
            return AppColors.success
        }
        switch booking.status {
        case .completed:
            return AppColors.success
        case .cancelled:
            return AppColors.danger
        case .checkedIn:
            return AppColors.brand
        case .confirmed:
            return AppColors.accent
        case .pending:
            return AppColors.warning
        case .noShow:
            return AppColors.danger
        }
    }
}

// MARK: - Quick Book Card
struct QuickBookCard: View {
    let duration: String
    let price: String
    let isSelected: Bool
    let lastGym: String?
    let lastDate: String
    let lastPrice: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration)
                        .font(AppFonts.h5)
                        .foregroundColor(Color(.label))
                    
                    Text(price)
                        .font(AppFonts.bodySmall)
                        .foregroundColor(AppColors.brand)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let lastGym = lastGym {
                        Text(lastGym)
                            .font(AppFonts.caption)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        HStack(spacing: 4) {
                            Text(lastDate)
                            Text("•")
                            Text(lastPrice)
                        }
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.md)
                    .stroke(isSelected ? AppColors.brand : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppRouter())
        .environmentObject(LocationService.shared)
        .environment(\.appContainer, .demo())
}
