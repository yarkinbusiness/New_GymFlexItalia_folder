//
//  GymFilters.swift
//  Gym Flex Italia
//
//  Model for gym search/filter options
//

import Foundation

/// Filters for gym search and discovery
struct GymFilters: Equatable {
    /// Minimum price per hour
    var minPrice: Double?
    
    /// Maximum price per hour
    var maxPrice: Double?
    
    /// Minimum rating (1-5)
    var minRating: Double?
    
    /// Required amenities
    var amenities: Set<Amenity> = []
    
    /// Required equipment
    var equipment: Set<Equipment> = []
    
    /// Workout types filter
    var workoutTypes: Set<WorkoutType> = []
    
    /// Maximum distance in meters
    var maxDistance: Double?
    
    /// Only show open gyms
    var openNow: Bool = false
    
    /// Only show verified gyms
    var verifiedOnly: Bool = false
    
    /// Whether any filters are active
    var hasActiveFilters: Bool {
        minPrice != nil ||
        maxPrice != nil ||
        minRating != nil ||
        !amenities.isEmpty ||
        !equipment.isEmpty ||
        !workoutTypes.isEmpty ||
        maxDistance != nil ||
        openNow ||
        verifiedOnly
    }
    
    /// Reset all filters to defaults
    mutating func reset() {
        minPrice = nil
        maxPrice = nil
        minRating = nil
        amenities.removeAll()
        equipment.removeAll()
        workoutTypes.removeAll()
        maxDistance = nil
        openNow = false
        verifiedOnly = false
    }
}
