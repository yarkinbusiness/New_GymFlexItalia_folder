//
//  BookingHistoryView.swift
//  Gym Flex Italia
//
//  Booking history view with upcoming and past bookings
//

import SwiftUI

/// Booking history view with segmented control for Upcoming/Past
struct BookingHistoryView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    
    @StateObject private var viewModel = BookingHistoryViewModel()
    
    @State private var selectedSegment = 0
    
    private let segments = ["Upcoming", "Past"]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Bookings", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            DemoTapLogger.log("BookingHistory.Open")
            await viewModel.load(using: appContainer.bookingHistoryService)
        }
        .refreshable {
            await viewModel.refresh(using: appContainer.bookingHistoryService)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading bookings...")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Error Banner
            if let error = viewModel.errorMessage {
                InlineErrorBanner(
                    message: error,
                    type: .error,
                    onDismiss: { viewModel.clearError() }
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
            }
            
            // Success Banner
            if let success = viewModel.successMessage {
                InlineErrorBanner(
                    message: success,
                    type: .success,
                    onDismiss: { viewModel.clearSuccess() }
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
            }
            
            // Bookings List
            if selectedSegment == 0 {
                upcomingList
            } else {
                pastList
            }
        }
    }
    
    // MARK: - Upcoming List
    
    private var upcomingList: some View {
        Group {
            if viewModel.hasUpcoming {
                ScrollView {
                    VStack(alignment: .leading, spacing: GFSpacing.sm) {
                        GFSectionHeader("Upcoming")
                            .padding(.horizontal, GFSpacing.lg)
                        
                        LazyVStack(spacing: GFSpacing.md) {
                            ForEach(viewModel.upcomingBookings) { booking in
                                BookingCard(booking: booking) {
                                    DemoTapLogger.log("BookingHistory.SelectBooking", context: "id: \(booking.id)")
                                    router.pushBookingDetail(bookingId: booking.id)
                                }
                            }
                        }
                        .padding(.horizontal, GFSpacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            } else {
                emptyUpcomingView
            }
        }
    }
    
    // MARK: - Past List
    
    private var pastList: some View {
        Group {
            if viewModel.hasPast {
                ScrollView {
                    VStack(alignment: .leading, spacing: GFSpacing.sm) {
                        GFSectionHeader("Past")
                            .padding(.horizontal, GFSpacing.lg)
                        
                        LazyVStack(spacing: GFSpacing.md) {
                            ForEach(viewModel.pastBookings) { booking in
                                BookingCard(booking: booking) {
                                    DemoTapLogger.log("BookingHistory.SelectBooking", context: "id: \(booking.id)")
                                    router.pushBookingDetail(bookingId: booking.id)
                                }
                            }
                        }
                        .padding(.horizontal, GFSpacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            } else {
                emptyPastView
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyUpcomingView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Upcoming Bookings")
                .font(AppFonts.h4)
                .foregroundColor(.primary)
            
            Text("Book a gym session to get started!")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                DemoTapLogger.log("BookingHistory.FindGyms")
                router.handle(deepLink: .bookSession)
            } label: {
                Text("Find Gyms")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
    
    private var emptyPastView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Past Bookings")
                .font(AppFonts.h4)
                .foregroundColor(.primary)
            
            Text("Your completed bookings will appear here.")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
    }
}

// MARK: - Booking Card Component

struct BookingCard: View {
    let booking: Booking
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header: Gym Name + Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.gymName ?? "Gym")
                            .font(AppFonts.h5)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let address = booking.gymAddress {
                            Text(address)
                                .font(AppFonts.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    BookingStatusBadge(status: booking.status)
                }
                
                Divider()
                
                // Details: Date, Time, Duration, Price
                HStack(spacing: Spacing.lg) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(formattedDate)
                                .font(AppFonts.bodySmall)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(formattedTime)
                                .font(AppFonts.bodySmall)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Duration & Price
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(booking.formattedDuration)
                            .font(AppFonts.bodySmall)
                            .foregroundColor(.secondary)
                        
                        Text(formattedPrice)
                            .font(AppFonts.h5)
                            .foregroundColor(AppColors.brand)
                    }
                }
                
                // Reference code for upcoming bookings
                if booking.isUpcoming, let code = booking.checkinCode {
                    HStack {
                        Text("Ref: \(code)")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(GFSpacing.lg)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: GFCorners.card))
            .gfSubtleShadow()
        }
        .buttonStyle(.plain)
    }
    
    private var formattedDate: String {
        booking.startTime.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var formattedTime: String {
        booking.startTime.formatted(date: .omitted, time: .shortened)
    }
    
    private var formattedPrice: String {
        String(format: "€%.2f", booking.totalPrice)
    }
}

// MARK: - Booking Status Badge

struct BookingStatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        GFStatusBadge(
            status.displayName,
            style: badgeStyle,
            icon: status.icon
        )
    }
    
    private var badgeStyle: GFBadgeStyle {
        switch status {
        case .confirmed:
            return .success
        case .checkedIn:
            return .success
        case .completed:
            return .info
        case .cancelled:
            return .danger
        case .pending:
            return .warning
        case .noShow:
            return .danger
        }
    }
}

#Preview {
    NavigationStack {
        BookingHistoryView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
