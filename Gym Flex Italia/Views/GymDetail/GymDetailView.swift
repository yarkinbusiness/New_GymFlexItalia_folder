//
//  GymDetailView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Gym detail view
struct GymDetailView: View {
    
    let gymId: String
    @StateObject private var viewModel = GymDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContainer) private var appContainer
    @State private var showConfirmationAlert = false
    
    var body: some View {
        ScrollView {
            if let gym = viewModel.gym {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover image
                    coverImage
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Booking confirmation banner (if present)
                        if let confirmation = viewModel.bookingConfirmation {
                            bookingConfirmationBanner(confirmation)
                        }
                        
                        // Error banner (if present)
                        if let error = viewModel.errorMessage {
                            errorBanner(error)
                        }
                        
                        // Header
                        headerSection(gym: gym)
                        
                        // Quick info
                        quickInfoSection(gym: gym)
                        
                        // Description
                        if let description = gym.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Amenities
                        amenitiesSection(gym: gym)
                        
                        // Equipment
                        equipmentSection(gym: gym)
                        
                        // Book button (hide if already booked)
                        if viewModel.bookingConfirmation == nil {
                            PrimaryButton("Book Now", icon: "calendar.badge.plus") {
                                DemoTapLogger.log("GymDetail.BookNow")
                                viewModel.showBookingForm = true
                            }
                            .confirmationDialog("Select Duration", isPresented: $viewModel.showBookingForm, titleVisibility: .visible) {
                                Button("1 Hour - €\(String(format: "%.2f", (gym.pricePerHour)))") {
                                    DemoTapLogger.log("GymDetail.Book1Hour", context: "gymId: \(gym.id)")
                                    Task {
                                        if await viewModel.bookGym(date: Date(), duration: 60, using: appContainer.bookingService) {
                                            showConfirmationAlert = true
                                        }
                                    }
                                }
                                Button("1.5 Hours - €\(String(format: "%.2f", (gym.pricePerHour * 1.5)))") {
                                    DemoTapLogger.log("GymDetail.Book1.5Hours", context: "gymId: \(gym.id)")
                                    Task {
                                        if await viewModel.bookGym(date: Date(), duration: 90, using: appContainer.bookingService) {
                                            showConfirmationAlert = true
                                        }
                                    }
                                }
                                Button("2 Hours - €\(String(format: "%.2f", (gym.pricePerHour * 2)))") {
                                    DemoTapLogger.log("GymDetail.Book2Hours", context: "gymId: \(gym.id)")
                                    Task {
                                        if await viewModel.bookGym(date: Date(), duration: 120, using: appContainer.bookingService) {
                                            showConfirmationAlert = true
                                        }
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading gym...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) {
                    Task {
                        await viewModel.loadGym(gymId: gymId, using: appContainer.gymService)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadGym(gymId: gymId, using: appContainer.gymService)
        }
        .alert("Booking Confirmed!", isPresented: $showConfirmationAlert) {
            Button("OK") { }
        } message: {
            if let confirmation = viewModel.bookingConfirmation {
                Text("Reference: \(confirmation.referenceCode)\n\nYou're all set! Show this code at the gym.")
            }
        }
    }
    
    // MARK: - Booking Confirmation Banner
    private func bookingConfirmationBanner(_ confirmation: BookingConfirmation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Booking Confirmed")
                    .font(AppFonts.h5)
                    .foregroundColor(.green)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reference Code")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textDim)
                    Text(confirmation.referenceCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textHigh)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textDim)
                    Text("\(confirmation.duration) min")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textHigh)
                }
            }
            
            Text("Total: €\(String(format: "%.2f", confirmation.totalPrice))")
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textDim)
        }
        .padding(Spacing.md)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textHigh)
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textDim)
            }
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
    }
    
    // MARK: - Cover Image
    private var coverImage: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 250)
    }
    
    // MARK: - Header Section
    private func headerSection(gym: Gym) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(gym.name)
                        .font(.title.bold())
                    
                    if gym.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                    Text("\(gym.address), \(gym.city)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Quick Info
    private func quickInfoSection(gym: Gym) -> some View {
        HStack(spacing: 20) {
            if let rating = gym.rating {
                QuickInfoItem(
                    icon: "star.fill",
                    value: String(format: "%.1f", rating),
                    label: "\(gym.reviewCount) reviews"
                )
            }
            
            QuickInfoItem(
                icon: "eurosign.circle.fill",
                value: String(format: "€%.0f", gym.pricePerHour),
                label: "per hour"
            )
            
            if let distance = viewModel.distanceFromUser {
                QuickInfoItem(
                    icon: "location.circle.fill",
                    value: distance,
                    label: "away"
                )
            }
        }
    }
    
    // MARK: - Amenities
    private func amenitiesSection(gym: Gym) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amenities")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(gym.amenities, id: \.self) { amenity in
                    HStack {
                        Image(systemName: amenity.icon)
                            .foregroundColor(.blue)
                        Text(amenity.displayName)
                            .font(.body)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Equipment
    private func equipmentSection(gym: Gym) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equipment")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(gym.equipment, id: \.self) { equipment in
                        TagChip(equipment.displayName, icon: equipment.icon)
                    }
                }
            }
        }
    }
}

struct QuickInfoItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        GymDetailView(gymId: "gym_1")
    }
    .environment(\.appContainer, .demo())
}

