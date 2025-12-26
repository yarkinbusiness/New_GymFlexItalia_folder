//
//  BookingHistoryView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Booking history view matching LED design
struct BookingHistoryView: View {
    
    @StateObject private var viewModel = BookingViewModel()
    
    var body: some View {
        ZStack {
            // Dark background
            AppColors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.pastBookings.isEmpty {
                emptyStateView
            } else {
                recentActivityView
            }
        }
        .task {
            await viewModel.loadBookings()
        }
    }
    
    // MARK: - Recent Activity View
    private var recentActivityView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.brand)
                    
                    Text("Recent Activity")
                        .font(AppFonts.h1)
                        .foregroundColor(AppColors.textHigh)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                
                // Bookings List
                VStack(spacing: Spacing.sm) {
                    ForEach(viewModel.pastBookings) { booking in
                        BookingHistoryRow(booking: booking)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView(
            title: "No Bookings Yet",
            message: "Start your fitness journey by booking your first gym session!",
            icon: "calendar.badge.clock",
            actionTitle: "Find Gyms"
        ) {
            // Navigate to discovery
        }
    }
}

#Preview {
    BookingHistoryView()
}
