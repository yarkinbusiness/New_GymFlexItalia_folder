//
//  RootTabView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Root tab view with custom bottom tab bar matching Liquid design
struct RootTabView: View {
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var deepLinkQueue: DeepLinkQueue
    @Environment(\.appContainer) private var appContainer
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case discover = "Discover"
        case groups = "Groups"
        case checkIn = "Check-in"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .discover: return "safari.fill"
            case .groups: return "person.2.fill"
            case .checkIn: return "qrcode"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                // Content
                Group {
                    switch router.selectedTab {
                    case .home:
                        DashboardView()
                    case .discover:
                        GymDiscoveryView()
                    case .groups:
                        GroupsView()
                    case .checkIn:
                        CheckInHomeView()
                    case .profile:
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Bottom Tab Bar
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $router.selectedTab)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .gymDetail(let gymId):
                    GymDetailView(gymId: gymId)
                case .groupDetail(let groupId):
                    GroupChatView(groupId: groupId)
                case .groupNotFound(let message):
                    GroupInviteErrorView(message: message)
                case .bookingHistory:
                    BookingHistoryView()
                case .bookingDetail(let bookingId):
                    BookingDetailView(bookingId: bookingId)
                case .editProfile:
                    EditProfileView()
                case .settings:
                    SettingsView()
                case .wallet:
                    WalletFullView()
                case .walletTransactionDetail(let transactionId):
                    TransactionDetailView(transactionId: transactionId)
                case .checkIn(let bookingId):
                    CheckInView(bookingId: bookingId)
                #if DEBUG
                case .deepLinkSimulator:
                    DeepLinkSimulatorView()
                case .ownerMode:
                    OwnerModeView()
                #endif
                case .paymentMethods:
                    PaymentMethodsView()
                case .addCard:
                    AddCardView()
                case .accountSecurity:
                    AccountSecurityView()
                case .changePassword:
                    ChangePasswordView()
                case .devicesSessions:
                    DevicesSessionsView()
                case .deleteAccount:
                    DeleteAccountView()
                case .notificationsPreferences:
                    NotificationsPreferencesView()
                case .helpSupport:
                    HelpSupportView()
                case .faq:
                    FAQView()
                case .reportBug:
                    ReportBugView()
                case .terms:
                    TermsPlaceholderView()
                case .privacy:
                    PrivacyPlaceholderView()
                case .editAvatar:
                    EditAvatarView()
                case .updateGoals:
                    UpdateGoalsView()
                }
            }
            .task {
                // Consume any pending deep links (e.g., from cold start notification)
                consumePendingDeepLinks()
            }
            .onChange(of: deepLinkQueue.pending.count) { _, _ in
                // Also consume when new deep links are enqueued while app is running
                consumePendingDeepLinks()
            }
        }
    }
    
    /// Processes all pending deep links from the queue
    private func consumePendingDeepLinks() {
        while let link = deepLinkQueue.dequeue() {
            router.handle(deepLink: link)
        }
    }
}

// MARK: - Placeholder Views for Navigation Destinations
// These can be replaced with real views later

struct GroupDetailPlaceholderView: View {
    let groupId: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.brand)
            
            Text("Group Detail")
                .font(AppFonts.h2)
            
            Text("Group ID: \(groupId)")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Group")
    }
}

struct EditProfilePlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(AppColors.brand)
            
            Text("Edit Profile")
                .font(AppFonts.h2)
            
            Text("Coming soon...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Edit Profile")
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.brand)
            
            Text("Settings")
                .font(AppFonts.h2)
            
            Text("Coming soon...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Settings")
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: RootTabView.Tab
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTabView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(
                                selectedTab == tab
                                    ? AppColors.brand
                                    : Color(.secondaryLabel)
                            )
                        
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(
                                selectedTab == tab
                                    ? AppColors.brand
                                    : Color(.secondaryLabel)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, 34) // Safe area
        .background(
            Color(.secondarySystemBackground)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: -5)
        )
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppRouter())
        .environmentObject(AuthService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(AppearanceManager.shared)
        .environmentObject(BookingManager.shared)
        .environmentObject(SettingsStore())
        .environmentObject(DeepLinkQueue())
        .environment(\.appContainer, .demo())
}

