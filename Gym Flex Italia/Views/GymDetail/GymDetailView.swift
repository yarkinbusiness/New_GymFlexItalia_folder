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
    
    var body: some View {
        ScrollView {
            if let gym = viewModel.gym {
                VStack(alignment: .leading, spacing: 20) {
                    // Cover image
                    coverImage
                    
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        // Book button
                        PrimaryButton("Book Now", icon: "calendar.badge.plus") {
                            viewModel.showBookingForm = true
                        }
                        .confirmationDialog("Select Duration", isPresented: $viewModel.showBookingForm, titleVisibility: .visible) {
                            Button("1 Hour - €\(String(format: "%.2f", (gym.pricePerHour)))") {
                                Task {
                                    if await viewModel.createBooking(duration: 60) {
                                        dismiss()
                                    }
                                }
                            }
                            Button("1.5 Hours - €\(String(format: "%.2f", (gym.pricePerHour * 1.5)))") {
                                Task {
                                    if await viewModel.createBooking(duration: 90) {
                                        dismiss()
                                    }
                                }
                            }
                            Button("2 Hours - €\(String(format: "%.2f", (gym.pricePerHour * 2)))") {
                                Task {
                                    if await viewModel.createBooking(duration: 120) {
                                        dismiss()
                                    }
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .padding()
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) {
                    Task {
                        await viewModel.loadGym(gymId: gymId)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadGym(gymId: gymId)
        }
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
        GymDetailView(gymId: "1")
    }
}

