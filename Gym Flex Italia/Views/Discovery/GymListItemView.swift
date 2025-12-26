//
//  GymListItemView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Gym list item card
struct GymListItemView: View {
    
    let gym: Gym
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Cover image placeholder
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            if gym.isVerified {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .padding(8)
                                }
                            }
                            Spacer()
                        }
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(gym.name)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text(gym.city)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        // Rating
                        if let rating = gym.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                            .font(.caption.weight(.semibold))
                        }
                        
                        Spacer()
                        
                        // Price
                        Text("€\(gym.pricePerHour, specifier: "%.0f")/hr")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    // Amenities
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(gym.amenities.prefix(4), id: \.self) { amenity in
                                TagChip(amenity.displayName, icon: amenity.icon)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    GymListItemView(gym: Gym(
        id: "1",
        name: "FitZone Milano",
        description: nil,
        address: "Via Roma 123",
        city: "Milano",
        region: "Lombardia",
        postalCode: "20100",
        country: "Italy",
        latitude: 45.4642,
        longitude: 9.1900,
        pricePerHour: 15.0,
        currency: "EUR",
        coverImageURL: nil,
        imageURLs: [],
        amenities: [.wifi, .showers, .lockers, .parking],
        equipment: [],
        workoutTypes: [.cardio, .strength],
        phoneNumber: nil,
        email: nil,
        website: nil,
        openingHours: nil,
        rating: 4.5,
        reviewCount: 128,
        totalBookings: 450,
        isActive: true,
        isVerified: true,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .padding()
}

