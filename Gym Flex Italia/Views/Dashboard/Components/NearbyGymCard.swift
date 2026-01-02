//
//  NearbyGymCard.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import SwiftUI

struct NearbyGymCard: View {
    var name: String?
    var address: String?
    var distance: String?
    var price: String?
    var rating: Double?
    
    var gym: Gym?
    
    init(gym: Gym) {
        self.gym = gym
        self.name = gym.name
        self.address = gym.address
        self.distance = nil // Will calculate from location
        self.price = String(format: "€%.0f/h", gym.pricePerHour)
        self.rating = gym.rating
    }
    
    init(name: String, address: String, distance: String, price: String, rating: Double) {
        self.name = name
        self.address = address
        self.distance = distance
        self.price = price
        self.rating = rating
    }
    
    var body: some View {
        Button {
            // Navigate to gym detail
        } label: {
            GFCard(padding: GFSpacing.md, showShadow: false) {
                HStack(alignment: .center, spacing: GFSpacing.md) {
                    VStack(alignment: .leading, spacing: GFSpacing.xs) {
                        Text(name ?? "Gym")
                            .gfSection()
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Text(address ?? "")
                                .gfCaption()
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            if let distance = distance {
                                Text("• \(distance)")
                                    .gfCaption(.medium)
                                    .foregroundColor(AppColors.brand)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: GFSpacing.xs) {
                        if let price = price {
                            Text(price)
                                .gfSection(.bold)
                                .foregroundColor(AppColors.brand)
                        }
                        
                        if let rating = rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.warning)
                                Text(String(format: "%.1f", rating))
                                    .gfCaption(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
