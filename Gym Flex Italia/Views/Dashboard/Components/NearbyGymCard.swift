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
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(name ?? "Gym")
                        .font(AppFonts.h5)
                        .foregroundColor(AppColors.textHigh)
                    
                    HStack(spacing: 4) {
                        Text(address ?? "")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.textDim)
                            .lineLimit(1)
                        
                        if let distance = distance {
                            Text("• \(distance)")
                                .font(AppFonts.bodySmall)
                                .foregroundColor(AppColors.brand)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    if let price = price {
                        Text(price)
                            .font(AppFonts.h5)
                            .foregroundColor(AppColors.brand)
                    }
                    
                    if let rating = rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.warning)
                            Text(String(format: "%.1f", rating))
                                .font(AppFonts.bodySmall)
                                .foregroundColor(AppColors.textHigh)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
