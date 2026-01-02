//
//  DiscoveryFilterSheet.swift
//  Gym Flex Italia
//
//  Filter sheet for gym discovery.
//

import SwiftUI

/// Filter sheet for refining gym search
struct DiscoveryFilterSheet: View {
    
    @Binding var filter: DiscoveryFilter
    @Environment(\.dismiss) private var dismiss
    
    // Local state for editing
    @State private var distanceEnabled: Bool = false
    @State private var maxDistance: Double = 5.0
    @State private var priceEnabled: Bool = false
    @State private var minPrice: Double = 0.0
    @State private var maxPrice: Double = 10.0
    @State private var ratingEnabled: Bool = false
    @State private var minRating: Double = 4.0
    @State private var selectedAmenities: Set<Amenity> = []
    
    init(filter: Binding<DiscoveryFilter>) {
        self._filter = filter
        
        // Initialize local state from filter
        let f = filter.wrappedValue
        _distanceEnabled = State(initialValue: f.maxDistanceKm != nil)
        _maxDistance = State(initialValue: f.maxDistanceKm ?? 5.0)
        _priceEnabled = State(initialValue: f.priceRange != nil)
        _minPrice = State(initialValue: f.priceRange?.lowerBound ?? 0.0)
        _maxPrice = State(initialValue: f.priceRange?.upperBound ?? 10.0)
        _ratingEnabled = State(initialValue: f.minRating != nil)
        _minRating = State(initialValue: f.minRating ?? 4.0)
        _selectedAmenities = State(initialValue: f.requiredAmenities)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Distance Section
                distanceSection
                
                // Price Section
                priceSection
                
                // Rating Section
                ratingSection
                
                // Amenities Section
                amenitiesSection
                
                // Reset Button
                resetSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Distance Section
    
    private var distanceSection: some View {
        Section {
            Toggle("Filter by Distance", isOn: $distanceEnabled.animation())
            
            if distanceEnabled {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Maximum Distance")
                            .font(AppFonts.body)
                        
                        Spacer()
                        
                        Text("\(Int(maxDistance)) km")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.brand)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(AppColors.brand.opacity(0.1))
                            .cornerRadius(CornerRadii.sm)
                    }
                    
                    Slider(value: $maxDistance, in: 1...20, step: 1)
                        .tint(AppColors.brand)
                }
            }
        } header: {
            Label("Distance", systemImage: "location")
        } footer: {
            if distanceEnabled {
                Text("Show gyms within \(Int(maxDistance)) km of your location")
            }
        }
    }
    
    // MARK: - Price Section
    
    private var priceSection: some View {
        Section {
            Toggle("Filter by Price", isOn: $priceEnabled.animation())
            
            if priceEnabled {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Price Range")
                            .font(AppFonts.body)
                        
                        Spacer()
                        
                        Text("€\(String(format: "%.0f", minPrice)) - €\(String(format: "%.0f", maxPrice))/hr")
                            .font(AppFonts.bodySmall)
                            .foregroundColor(AppColors.success)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 4)
                            .background(AppColors.success.opacity(0.1))
                            .cornerRadius(CornerRadii.sm)
                    }
                    
                    // Min Price
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Min: €\(String(format: "%.0f", minPrice))")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $minPrice, in: 0...min(maxPrice - 1, 15), step: 1)
                            .tint(AppColors.success)
                    }
                    
                    // Max Price
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max: €\(String(format: "%.0f", maxPrice))")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $maxPrice, in: max(minPrice + 1, 1)...20, step: 1)
                            .tint(AppColors.success)
                    }
                }
            }
        } header: {
            Label("Price", systemImage: "eurosign.circle")
        }
    }
    
    // MARK: - Rating Section
    
    private var ratingSection: some View {
        Section {
            Toggle("Minimum Rating", isOn: $ratingEnabled.animation())
            
            if ratingEnabled {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Minimum")
                            .font(AppFonts.body)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", minRating))
                        }
                        .font(AppFonts.bodySmall)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(CornerRadii.sm)
                    }
                    
                    Slider(value: $minRating, in: 1...5, step: 0.5)
                        .tint(.yellow)
                }
            }
        } header: {
            Label("Rating", systemImage: "star")
        }
    }
    
    // MARK: - Amenities Section
    
    private var amenitiesSection: some View {
        Section {
            ForEach(Amenity.allCases, id: \.self) { amenity in
                Button {
                    toggleAmenity(amenity)
                } label: {
                    HStack {
                        Image(systemName: amenity.icon)
                            .foregroundColor(selectedAmenities.contains(amenity) ? AppColors.brand : .secondary)
                            .frame(width: 24)
                        
                        Text(amenity.displayName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedAmenities.contains(amenity) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.brand)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Label("Required Amenities", systemImage: "checkmark.circle")
        } footer: {
            if !selectedAmenities.isEmpty {
                Text("\(selectedAmenities.count) amenities required")
            }
        }
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                resetFilters()
            } label: {
                HStack {
                    Spacer()
                    Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleAmenity(_ amenity: Amenity) {
        if selectedAmenities.contains(amenity) {
            selectedAmenities.remove(amenity)
        } else {
            selectedAmenities.insert(amenity)
        }
    }
    
    private func applyFilters() {
        filter.maxDistanceKm = distanceEnabled ? maxDistance : nil
        filter.priceRange = priceEnabled ? minPrice...maxPrice : nil
        filter.minRating = ratingEnabled ? minRating : nil
        filter.requiredAmenities = selectedAmenities
    }
    
    private func resetFilters() {
        distanceEnabled = false
        maxDistance = 5.0
        priceEnabled = false
        minPrice = 0.0
        maxPrice = 10.0
        ratingEnabled = false
        minRating = 4.0
        selectedAmenities = []
    }
}

#Preview {
    DiscoveryFilterSheet(filter: .constant(.default()))
}
