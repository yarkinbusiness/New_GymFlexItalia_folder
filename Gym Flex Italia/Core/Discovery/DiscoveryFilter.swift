//
//  DiscoveryFilter.swift
//  Gym Flex Italia
//
//  Filter model for gym discovery.
//

import Foundation

/// Filter model for gym discovery
/// Used to filter the canonical gym list in DiscoveryViewModel
struct DiscoveryFilter: Equatable {
    /// Search text for name/address filtering
    var searchText: String = ""
    
    /// Maximum distance in kilometers (nil = no limit)
    var maxDistanceKm: Double? = nil
    
    /// Price range filter (nil = no limit)
    var priceRange: ClosedRange<Double>? = nil
    
    /// Required amenities (empty = no filter)
    var requiredAmenities: Set<Amenity> = []
    
    /// Required equipment (empty = no filter)
    var requiredEquipment: Set<Equipment> = []
    
    /// Minimum rating filter (nil = no limit)
    var minRating: Double? = nil
    
    /// Whether any filters are active (excluding search)
    var hasActiveFilters: Bool {
        maxDistanceKm != nil ||
        priceRange != nil ||
        !requiredAmenities.isEmpty ||
        !requiredEquipment.isEmpty ||
        minRating != nil
    }
    
    /// Whether search text is active
    var hasSearchText: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Count of active filters (for badge display)
    var activeFilterCount: Int {
        var count = 0
        if maxDistanceKm != nil { count += 1 }
        if priceRange != nil { count += 1 }
        if !requiredAmenities.isEmpty { count += 1 }
        if !requiredEquipment.isEmpty { count += 1 }
        if minRating != nil { count += 1 }
        return count
    }
    
    /// Resets all filters to defaults
    mutating func reset() {
        searchText = ""
        maxDistanceKm = nil
        priceRange = nil
        requiredAmenities = []
        requiredEquipment = []
        minRating = nil
    }
    
    /// Default filter with no constraints
    static func `default`() -> DiscoveryFilter {
        DiscoveryFilter()
    }
}

// MARK: - Preset Filters

extension DiscoveryFilter {
    /// Nearby gyms within 5km
    static func nearby() -> DiscoveryFilter {
        var filter = DiscoveryFilter()
        filter.maxDistanceKm = 5.0
        return filter
    }
    
    /// Budget-friendly gyms
    static func budget() -> DiscoveryFilter {
        var filter = DiscoveryFilter()
        filter.priceRange = 0...3.0
        return filter
    }
    
    /// Premium gyms (high rating)
    static func premium() -> DiscoveryFilter {
        var filter = DiscoveryFilter()
        filter.minRating = 4.5
        return filter
    }
}
