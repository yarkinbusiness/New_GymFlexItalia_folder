//
//  DashboardView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Main dashboard view matching LED design
struct DashboardView: View {
    
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var showWallet = false
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header Section
                    headerSection
                    
                    // Active Session or Quick Book Section
                    if let activeBooking = viewModel.activeBooking {
                        ActiveSessionSummaryCard(booking: activeBooking) {
                            // Switch to Check-in tab
                            DemoTapLogger.log("Dashboard.ActiveSession")
                            router.switchToTab(.checkIn)
                        }
                    } else {
                        quickBookSection
                    }
                    
                    // Nearby Gyms Section
                    nearbyGymsSection
                    
                    // Recent Activity Section
                    recentActivitySection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 100) // Space for tab bar
            }
            .refreshable {
                await viewModel.refreshData()
            }
            
            if viewModel.isLoading {
                LoadingOverlayView()
            }
        }
        .task {
            await viewModel.loadDashboard()
        }
        // WalletView is now navigated via router
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
            
            VStack(spacing: Spacing.sm) {
                QuickBookCard(
                    duration: "1 Hour",
                    price: "€2",
                    isSelected: true,
                    lastGym: viewModel.lastBookedGym?.name,
                    lastDate: "5 days ago",
                    lastPrice: "€4.00"
                ) {
                    Task {
                        DemoTapLogger.log("Dashboard.QuickBook1Hour")
                        if let _ = await viewModel.createBooking(gymId: "gym_001", duration: 60) {
                            // Successfully created booking, navigate to Check-in tab
                            router.switchToTab(.checkIn)
                        }
                    }
                }
                
                QuickBookCard(
                    duration: "1.5 Hours",
                    price: "€3",
                    isSelected: false,
                    lastGym: viewModel.lastBookedGym?.name,
                    lastDate: "5 days ago",
                    lastPrice: "€4.00"
                ) {
                    Task {
                        DemoTapLogger.log("Dashboard.QuickBook1.5Hours")
                        if let _ = await viewModel.createBooking(gymId: "gym_001", duration: 90) {
                            // Successfully created booking, navigate to Check-in tab
                            router.switchToTab(.checkIn)
                        }
                    }
                }
                
                QuickBookCard(
                    duration: "2 Hours",
                    price: "€4",
                    isSelected: false,
                    lastGym: viewModel.lastBookedGym?.name,
                    lastDate: "5 days ago",
                    lastPrice: "€4.00"
                ) {
                    Task {
                        DemoTapLogger.log("Dashboard.QuickBook2Hours")
                        if let _ = await viewModel.createBooking(gymId: "gym_001", duration: 120) {
                            // Successfully created booking, navigate to Check-in tab
                            router.switchToTab(.checkIn)
                        }
                    }
                }
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
            
            VStack(spacing: Spacing.sm) {
                if !viewModel.nearbyGyms.isEmpty {
                    ForEach(viewModel.nearbyGyms.prefix(3)) { gym in
                        NearbyGymCard(gym: gym)
                    }
                } else {
                    // Placeholder data
                    NearbyGymCard(
                        name: "MaxFit San Lorenzo",
                        address: "Via dei Sardi 40, Rome",
                        distance: "2 km",
                        price: "€3/h",
                        rating: 4.5
                    )
                    
                    NearbyGymCard(
                        name: "Elite Fitness Termini",
                        address: "Via Marsala 89, Rome",
                        distance: "3 km",
                        price: "€4/h",
                        rating: 4.8
                    )
                    
                    NearbyGymCard(
                        name: "FitnessPro Parioli",
                        address: "Via Archimede 50, Rome",
                        distance: "0.5 km",
                        price: "€4/h",
                        rating: 4.6
                    )
                }
            }
        }
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
                    router.switchToTab(.profile)
                }
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.brand)
            }
            
            VStack(spacing: Spacing.sm) {
                if !viewModel.recentBookings.isEmpty {
                    ForEach(viewModel.recentBookings.prefix(3)) { booking in
                        RecentActivityCard(booking: booking)
                    }
                } else {
                    // Placeholder
                    RecentActivityCard(
                        gymName: "UrbanFit Villa Borghese",
                        date: "Yesterday",
                        price: "€4.00",
                        status: "Completed"
                    )
                    
                    RecentActivityCard(
                        gymName: "MaxFit San Lorenzo",
                        date: "3 days ago",
                        price: "€3.00",
                        status: "Completed"
                    )
                }
            }
        }
    }
}

// MARK: - Recent Activity Card
struct RecentActivityCard: View {
    var gymName: String?
    var date: String?
    var price: String?
    var status: String?
    
    var booking: Booking?
    
    init(booking: Booking) {
        self.booking = booking
        self.gymName = booking.gymName
        self.date = booking.startTime.formatted(date: .numeric, time: .omitted)
        self.price = String(format: "€%.2f", booking.totalPrice)
        self.status = booking.status.displayName
    }
    
    init(gymName: String, date: String, price: String, status: String) {
        self.gymName = gymName
        self.date = date
        self.price = price
        self.status = status
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gymName ?? "Gym")
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                
                if let date = date {
                    Text(date)
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let price = price {
                    Text(price)
                        .font(AppFonts.h5)
                        .foregroundColor(Color(.label))
                }
                
                if let status = status {
                    Text(status)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.danger)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.danger.opacity(0.2))
                        )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        .environment(\.appContainer, .demo())
}
