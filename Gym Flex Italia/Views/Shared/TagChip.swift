//
//  TagChip.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Tag chip component for categories, amenities, etc.
struct TagChip: View {
    
    let text: String
    let icon: String?
    var isSelected: Bool = false
    var action: (() -> Void)?
    
    init(_ text: String, icon: String? = nil, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.text = text
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    chipContent
                }
            } else {
                chipContent
            }
        }
    }
    
    private var chipContent: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
        )
        .foregroundColor(isSelected ? .white : .primary)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Selectable tag chip for filters
struct SelectableTagChip: View {
    
    let text: String
    let icon: String?
    @Binding var isSelected: Bool
    
    init(_ text: String, icon: String? = nil, isSelected: Binding<Bool>) {
        self.text = text
        self.icon = icon
        self._isSelected = isSelected
    }
    
    var body: some View {
        TagChip(text, icon: icon, isSelected: isSelected) {
            isSelected.toggle()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Static tags
        HStack {
            TagChip("Cardio", icon: "heart.fill")
            TagChip("Strength", icon: "dumbbell.fill")
            TagChip("Yoga", icon: "figure.mind.and.body")
        }
        
        // Selected tags
        HStack {
            TagChip("WiFi", icon: "wifi", isSelected: true)
            TagChip("Parking", icon: "parkingsign.circle.fill", isSelected: true)
            TagChip("Sauna", icon: "flame.fill", isSelected: false)
        }
        
        // Interactive tags
        HStack {
            TagChip("Beginner", isSelected: false) {
                print("Tapped")
            }
            TagChip("Advanced", isSelected: true) {
                print("Tapped")
            }
        }
    }
    .padding()
}

