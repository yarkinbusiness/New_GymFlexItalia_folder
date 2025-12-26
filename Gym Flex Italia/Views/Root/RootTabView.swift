//
//  RootTabView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Root tab view with custom bottom tab bar matching Liquid design
struct RootTabView: View {
    
    @StateObject private var tabManager = TabManager.shared
    @EnvironmentObject var appearanceManager: AppearanceManager
    
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
        ZStack {
            // Content
            Group {
                switch tabManager.selectedTab {
                case .home:
                    DashboardView()
                case .discover:
                    GymDiscoveryView()
                case .groups:
                    GroupsView()
                case .checkIn:
                    QRCheckinView(bookingId: "") // Will show empty state if no booking
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Bottom Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $tabManager.selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
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
}
