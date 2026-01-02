//
//  ProfileView.swift
//  Gym Flex Italia
//
//  Profile view using canonical stores via AppContainer.
//  Wallet balance from WalletStore, booking stats from MockBookingStore.
//

import SwiftUI

/// Profile view matching Liquid design
struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var router: AppRouter
    @Environment(\.appContainer) var appContainer
    
    // No placeholder sheets - using navigation routes
    
    var body: some View {
        ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.profile == nil {
                // Loading state
                loadingView
            } else if viewModel.errorMessage != nil && viewModel.profile == nil {
                // Error state
                errorView
            } else {
                // Content
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Profile Header
                        profileHeaderSection
                        
                        // Wallet Summary
                        if FeatureFlags.shared.isWalletEnabled {
                            walletSummarySection
                        }
                        
                        // Payment Methods
                        if FeatureFlags.shared.isWalletEnabled {
                            paymentMethodsRow
                        }
                        
                        // Booking Summary
                        bookingSummarySection
                        
                        // Weekly Progress
                        weeklyProgressSection
                        
                        // Appearance Settings
                        appearanceSection
                        
                        // Personal Information
                        personalInfoSection
                        
                        // Account & Security
                        accountSecurityRow
                        
                        // Notifications & Preferences
                        notificationsRow
                        
                        // Help & Support
                        helpSupportRow
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, 100) // Space for tab bar
                }
                .refreshable {
                    await viewModel.refresh(using: appContainer)
                }
            }
        }
        .task {
            await viewModel.load(using: appContainer)
        }
        // Navigation is handled via AppRouter routes
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                .scaleEffect(1.5)
            
            Text("Loading profile...")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.danger)
            
            Text("Failed to load profile")
                .font(AppFonts.h3)
                .foregroundColor(.primary)
            
            Text(viewModel.errorMessage ?? "An error occurred")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                DemoTapLogger.log("Profile.Retry")
                Task {
                    await viewModel.retry(using: appContainer)
                }
            } label: {
                Text("Retry")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.xl)
    }
    
    // MARK: - Wallet Summary Section
    private var walletSummarySection: some View {
        Button {
            DemoTapLogger.log("Profile.WalletSummary")
            router.pushWallet()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.success.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.success)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallet Balance")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text(viewModel.formattedWalletBalance)
                        .font(AppFonts.h3)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Payment Methods Row
    private var paymentMethodsRow: some View {
        Button {
            DemoTapLogger.log("Profile.PaymentMethods")
            router.pushPaymentMethods()
        } label: {
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
                    Text("Payment Methods")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    let cardCount = PaymentMethodsStore.shared.cards.count
                    Text(cardCount == 0 ? "Add a payment method" : "\(cardCount) card\(cardCount == 1 ? "" : "s") saved")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Account & Security Row
    private var accountSecurityRow: some View {
        Button {
            DemoTapLogger.log("Profile.AccountSecurity")
            router.pushAccountSecurity()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.brand.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.brand)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account & Security")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    Text("Password, biometrics, devices")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Notifications Row
    private var notificationsRow: some View {
        Button {
            DemoTapLogger.log("Profile.Notifications")
            router.pushNotificationsPreferences()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.warning.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.warning)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications & Preferences")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    Text("Reminders, alerts, quiet hours")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Help & Support Row
    private var helpSupportRow: some View {
        Button {
            DemoTapLogger.log("Profile.HelpSupport")
            router.pushHelpSupport()
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadii.sm)
                        .fill(AppColors.success.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.success)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Help & Support")
                        .font(AppFonts.body)
                        .foregroundColor(Color(.label))
                    
                    Text("FAQ, contact, legal")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Spacing.lg)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Booking Summary Section
    private var bookingSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadii.sm)
                            .fill(AppColors.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.accent)
                    }
                    
                    Text("My Bookings")
                        .font(AppFonts.h4)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                Button {
                    DemoTapLogger.log("Profile.ViewAllBookings")
                    router.pushBookingHistory()
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(AppFonts.bodySmall)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.brand)
                }
            }
            
            // Stats Row
            HStack(spacing: Spacing.lg) {
                // Upcoming
                VStack(spacing: 4) {
                    Text("\(viewModel.upcomingCount)")
                        .font(AppFonts.h2)
                        .foregroundColor(AppColors.brand)
                    
                    Text("Upcoming")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Past
                VStack(spacing: 4) {
                    Text("\(viewModel.pastCount)")
                        .font(AppFonts.h2)
                        .foregroundColor(Color(.label))
                    
                    Text("Past")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Spacing.md)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(CornerRadii.md)
            
            // Last Booking
            if let summary = viewModel.lastBookingSummary {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text("Last booking: \(summary)")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text("No bookings yet")
                        .font(AppFonts.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
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
                DemoTapLogger.log("Profile.ToggleAppearance")
                settingsStore.toggleLightDark()
            } label: {
                HStack {
                    Image(systemName: settingsStore.appearanceIconName)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.brand)
                    
                    Text(settingsStore.appearanceDisplayName)
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
                    DemoTapLogger.log("Profile.EditAvatarBadge")
                    router.pushEditAvatar()
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
                    DemoTapLogger.log("Profile.EditAvatar")
                    router.pushEditAvatar()
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
                    DemoTapLogger.log("Profile.UpdateGoals")
                    router.pushUpdateGoals()
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
                    DemoTapLogger.log("Profile.EditPersonalInfo")
                    router.pushEditProfile()
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

// MARK: - Sheet Placeholder View
struct SheetPlaceholderView: View {
    let title: String
    let message: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.brand)
                
                Text(title)
                    .font(AppFonts.h2)
                
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textDim)
                    .multilineTextAlignment(.center)
                
                Button {
                    DemoTapLogger.log("Sheet.Done")
                    dismiss()
                } label: {
                    Text("Done")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
                }
                .padding(.horizontal, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
        .environmentObject(AppearanceManager.shared)
        .environmentObject(SettingsStore())
        .environment(\.appContainer, .demo())
}
