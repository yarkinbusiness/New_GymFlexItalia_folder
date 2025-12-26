//
//  ProfileView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Profile view matching Liquid design
struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Weekly Progress
                    weeklyProgressSection
                    
                    // Appearance Settings
                    appearanceSection
                    
                    // Personal Information
                    personalInfoSection
                    
                    // Payment Methods (if enabled)
                    if FeatureFlags.shared.isWalletEnabled {
                        paymentMethodsSection
                    }
                    
                    // Booking History
                    bookingHistorySection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, 100) // Space for tab bar
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                }
                
                Text("Appearance")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
            }
            
            Button {
                appearanceManager.toggleAppearance()
            } label: {
                HStack {
                    Image(systemName: appearanceManager.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.brand)
                    
                    Text(appearanceManager.displayName)
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(Spacing.md)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.md)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Profile Header
    private var profileHeaderSection: some View {
        VStack(spacing: Spacing.lg) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                // Avatar Circle
                ZStack {
                    Circle()
                        .fill(AppGradients.primary)
                        .frame(width: 120, height: 120)
                    
                    if let profile = viewModel.profile {
                        Text(AvatarConfig.emojiForStyle(profile.avatarStyle, level: profile.avatarLevel))
                            .font(.system(size: 60))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                }
                
                // Edit Badge
                Button {
                    // Edit avatar
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.brand)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Name & Email
            VStack(spacing: Spacing.xs) {
                Text(viewModel.profile?.fullName ?? "User")
                    .font(AppFonts.h2)
                    .foregroundColor(Color(.label))
                
                Text(viewModel.profile?.email ?? "email@example.com")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button {
                    // Edit avatar
                } label: {
                    Text("Edit Avatar")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.label))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(CornerRadii.md)
                }
                
                Button {
                    // Update goals
                } label: {
                    Text("Update Goals")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.label))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(CornerRadii.md)
                }
            }
        }
    }
    
    // MARK: - Weekly Progress
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppGradients.primary)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "target")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text("Weekly Progress")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("0 of 2 workouts")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12))
                        Text("0%")
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.brand)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadii.pill)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: CornerRadii.pill)
                            .fill(AppGradients.primary)
                            .frame(width: geometry.size.width * 0, height: 8)
                    }
                }
                .frame(height: 8)
                
                // Motivational Message
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(AppColors.brand)
                    Text("Let's crush this week!")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.label))
                    Text("🚀")
                        .font(.system(size: 16))
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Personal Information
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadii.sm)
                            .fill(AppColors.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    Text("Personal Information")
                        .font(AppFonts.h4)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                Button {
                    // Edit
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                        Text("Edit")
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            VStack(spacing: Spacing.sm) {
                InfoRow(
                    icon: "person.fill",
                    label: "Name",
                    value: viewModel.profile?.fullName ?? "Not set"
                )
                
                InfoRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: viewModel.profile?.email ?? "Not set"
                )
                
                InfoRow(
                    icon: "phone.fill",
                    label: "Phone",
                    value: viewModel.profile?.phoneNumber ?? "Not set"
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Payment Methods
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                }
                
                Text("Payment Methods")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
            }
            
            // Payment Card
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Visa •••• 4242")
                        .font(AppFonts.h5)
                        .foregroundColor(Color(.label))
                    
                    Text("Expires 12/25")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Text("Default")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.success.opacity(0.2))
                    )
            }
            .padding(Spacing.md)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(CornerRadii.md)
            
            Button {
                // Add payment method
            } label: {
                Text("+ Add Payment Method")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.brand)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Booking History
    private var bookingHistorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.accent)
                }
                
                Text("Booking History")
                    .font(AppFonts.h4)
                    .foregroundColor(Color(.label))
            }
            
            VStack(spacing: Spacing.sm) {
                if !viewModel.recentBookings.isEmpty {
                    ForEach(viewModel.recentBookings.prefix(3)) { booking in
                        BookingHistoryRow(booking: booking)
                    }
                } else {
                    // Placeholder data
                    BookingHistoryRow(
                        gymName: "UrbanFit Villa Borghese",
                        date: "11/11/2025",
                        duration: "1h",
                        price: "€4.00",
                        status: "expired"
                    )
                    
                    BookingHistoryRow(
                        gymName: "FitnessPro Parioli",
                        date: "11/6/2025",
                        duration: "1.5h",
                        price: "€6.00",
                        status: "expired"
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadii.sm)
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFonts.bodySmall)
                    .foregroundColor(Color(.secondaryLabel))
                
                Text(value)
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(CornerRadii.md)
    }
}

// MARK: - Booking History Row
struct BookingHistoryRow: View {
    var gymName: String?
    var date: String?
    var duration: String?
    var price: String?
    var status: String?
    
    var booking: Booking?
    
    init(booking: Booking) {
        self.booking = booking
        self.gymName = booking.gymName
        self.date = booking.startTime.formatted(date: .numeric, time: .omitted)
        self.duration = booking.formattedDuration
        self.price = String(format: "€%.2f", booking.totalPrice)
        self.status = booking.status.rawValue
    }
    
    init(gymName: String, date: String, duration: String, price: String, status: String) {
        self.gymName = gymName
        self.date = date
        self.duration = duration
        self.price = price
        self.status = status
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gymName ?? "Gym")
                    .font(AppFonts.h5)
                    .foregroundColor(Color(.label))
                
                if let date = date, let duration = duration {
                    Text("\(date) • \(duration)")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let price = price {
                    Text(price)
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.brand)
                }
                
                if let status = status {
                    Text(status)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.danger)
                    .textCase(.lowercase)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
