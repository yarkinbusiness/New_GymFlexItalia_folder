//
//  GymDiscoveryViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

/// ViewModel for gym discovery, search, and filtering
/// Uses MockDataStore as the canonical source for gym data
@MainActor
final class GymDiscoveryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All available gyms (from canonical source)
    @Published private(set) var allGyms: [Gym] = []
    
    /// Filtered gyms based on current filter settings
    /// This drives BOTH list and map views
    @Published private(set) var filteredGyms: [Gym] = []
    
    /// Currently selected gym (for map callout)
    @Published var selectedGym: Gym?
    
    /// Current filter settings
    @Published var filter: DiscoveryFilter = .default() {
        didSet { applyFilters() }
    }
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Current map region
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: AppConfig.Map.defaultLatitude,
            longitude: AppConfig.Map.defaultLongitude
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    /// Current view mode (list or map)
    @Published var viewMode: ViewMode = .list
    
    /// Whether filter sheet is shown
    @Published var showFilters = false
    
    // MARK: - Private Properties
    
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    
    enum ViewMode: String, CaseIterable {
        case list
        case map
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .map: return "map"
            }
        }
        
        var title: String {
            switch self {
            case .list: return "List"
            case .map: return "Map"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupLocationObserver()
        setupInitialRegion()
    }
    
    private func setupLocationObserver() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    self?.updateMapRegion(for: location.coordinate)
                    // Re-apply filters when location changes (for distance filtering)
                    self?.applyFilters()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupInitialRegion() {
        if let location = locationService.currentLocation {
            updateMapRegion(for: location.coordinate)
        } else {
            // Default to Rome center
            let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
            updateMapRegion(for: romeCenter)
        }
    }
    
    // MARK: - Load Gyms
    
    /// Load gyms from canonical MockDataStore
    func loadGyms() async {
        isLoading = true
        errorMessage = nil
        
        // Use canonical MockDataStore - single source of truth for gym data
        allGyms = MockDataStore.shared.gyms
        applyFilters()
        
        // Center map on user location or Rome center
        if let userLocation = locationService.currentLocation {
            updateMapRegion(for: userLocation.coordinate)
        }
        
        isLoading = false
    }
    
    /// Load gyms using injected service (for production/live mode)
    /// - Parameter service: The gym service to use for fetching data
    func loadGyms(using service: GymServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            allGyms = try await service.fetchGyms()
            applyFilters()
            
            if let userLocation = locationService.currentLocation {
                updateMapRegion(for: userLocation.coordinate)
            }
        } catch {
            errorMessage = error.localizedDescription
            // Fallback to canonical MockDataStore on error
            allGyms = MockDataStore.shared.gyms
            applyFilters()
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    /// Apply all filters in order: search → distance → price → amenities → rating
    func applyFilters() {
        var result = allGyms
        
        // 1. Search text filter (name + address + description)
        if filter.hasSearchText {
            let query = filter.searchText.lowercased().trimmingCharacters(in: .whitespaces)
            result = result.filter { gym in
                gym.name.lowercased().contains(query) ||
                gym.address.lowercased().contains(query) ||
                (gym.description?.lowercased().contains(query) ?? false) ||
                gym.city.lowercased().contains(query)
            }
        }
        
        // 2. Distance filter (only if user location available)
        if let maxDistance = filter.maxDistanceKm,
           let userLocation = locationService.currentLocation {
            result = result.filter { gym in
                let distanceKm = gym.distance(from: userLocation) / 1000.0
                return distanceKm <= maxDistance
            }
        }
        
        // 3. Price range filter
        if let priceRange = filter.priceRange {
            result = result.filter { gym in
                priceRange.contains(gym.pricePerHour)
            }
        }
        
        // 4. Amenities filter (gym must have ALL required amenities)
        if !filter.requiredAmenities.isEmpty {
            result = result.filter { gym in
                filter.requiredAmenities.isSubset(of: Set(gym.amenities))
            }
        }
        
        // 5. Equipment filter (gym must have ALL required equipment)
        if !filter.requiredEquipment.isEmpty {
            result = result.filter { gym in
                filter.requiredEquipment.isSubset(of: Set(gym.equipment))
            }
        }
        
        // 6. Rating filter
        if let minRating = filter.minRating {
            result = result.filter { gym in
                (gym.rating ?? 0) >= minRating
            }
        }
        
        // Sort by distance if location available, otherwise by rating
        if let userLocation = locationService.currentLocation {
            result.sort { gym1, gym2 in
                gym1.distance(from: userLocation) < gym2.distance(from: userLocation)
            }
        } else {
            result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
        
        filteredGyms = result
        
        #if DEBUG
        // Guardrail: Ensure filteredGyms is always a subset of allGyms
        let filteredIds = Set(filteredGyms.map { $0.id })
        let allIds = Set(allGyms.map { $0.id })
        assert(filteredIds.isSubset(of: allIds), "filteredGyms contains gyms not in allGyms!")
        #endif
    }
    
    /// Update search text and apply filters
    func updateSearchText(_ text: String) {
        filter.searchText = text
    }
    
    /// Clear all filters
    func clearFilters() {
        filter.reset()
    }
    
    /// Apply filters (called from filter sheet)
    func confirmFilters() {
        showFilters = false
        applyFilters()
    }
    
    // MARK: - Map
    
    func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func selectGym(_ gym: Gym) {
        selectedGym = gym
        updateMapRegion(for: gym.coordinate)
    }
    
    func zoomToShowAllGyms() {
        guard !filteredGyms.isEmpty else { return }
        
        let coordinates = filteredGyms.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 41.9
        let maxLat = coordinates.map { $0.latitude }.max() ?? 41.9
        let minLon = coordinates.map { $0.longitude }.min() ?? 12.5
        let maxLon = coordinates.map { $0.longitude }.max() ?? 12.5
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.3),
            longitudeDelta: max(0.02, (maxLon - minLon) * 1.3)
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Location
    
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func centerOnUserLocation() {
        if let location = locationService.currentLocation {
            updateMapRegion(for: location.coordinate)
        } else {
            locationService.requestOneTimeLocation()
            let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
            updateMapRegion(for: romeCenter)
        }
    }
    
    var userLocation: CLLocation? {
        locationService.currentLocation
    }
    
    // MARK: - Sorting
    
    func sortByDistance() {
        guard let userLocation = locationService.currentLocation else { return }
        
        filteredGyms.sort { gym1, gym2 in
            gym1.distance(from: userLocation) < gym2.distance(from: userLocation)
        }
    }
    
    func sortByPrice() {
        filteredGyms.sort { $0.pricePerHour < $1.pricePerHour }
    }
    
    func sortByRating() {
        filteredGyms.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
    }
    
    // MARK: - Helpers
    
    /// Format distance for display
    func formattedDistance(for gym: Gym) -> String? {
        guard let userLocation = locationService.currentLocation else { return nil }
        let distanceMeters = gym.distance(from: userLocation)
        
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m"
        } else {
            return String(format: "%.1fkm", distanceMeters / 1000)
        }
    }
}
