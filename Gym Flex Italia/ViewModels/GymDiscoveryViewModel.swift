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

/// ViewModel for gym discovery and search
@MainActor
final class GymDiscoveryViewModel: ObservableObject {
    
    @Published var gyms: [Gym] = []
    @Published var filteredGyms: [Gym] = []
    @Published var selectedGym: Gym?
    
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: AppConfig.Map.defaultLatitude,
            longitude: AppConfig.Map.defaultLongitude
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Published var filters = GymFilters()
    @Published var showFilters = false
    @Published var viewMode: ViewMode = .list
    
    private let gymsService = GymsService.shared
    private let locationService = LocationService.shared
    private let mockDataProvider = MockGymDataProvider.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum ViewMode {
        case list
        case map
    }
    
    init() {
        // Observe location updates
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { @MainActor in
                    self?.updateMapRegion(for: location.coordinate)
                }
            }
            .store(in: &cancellables)
        
        // Set initial region
        if let location = locationService.currentLocation {
            updateMapRegion(for: location.coordinate)
        } else {
            // Default to Rome center
            let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
            updateMapRegion(for: romeCenter)
        }
    }
    
    // MARK: - Load Gyms
    func loadGyms() async {
        isLoading = true
        errorMessage = nil
        
        // Use mock data for now - can be replaced with real API later
        gyms = mockDataProvider.generateRomeGyms()
        filteredGyms = gyms
        
        // Center map on user location or Rome center
        if let userLocation = locationService.currentLocation {
            updateMapRegion(for: userLocation.coordinate)
        } else {
            // Default to Rome center
            let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
            updateMapRegion(for: romeCenter)
        }
        
        isLoading = false
    }
    
    /// Load gyms using injected service (preferred for production)
    /// - Parameter service: The gym service to use for fetching data
    func loadGyms(using service: GymServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        
        do {
            gyms = try await service.fetchGyms()
            filteredGyms = gyms
            
            // Center map on user location or Rome center
            if let userLocation = locationService.currentLocation {
                updateMapRegion(for: userLocation.coordinate)
            } else {
                let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
                updateMapRegion(for: romeCenter)
            }
        } catch {
            errorMessage = error.localizedDescription
            // Fallback to mock data on error
            gyms = mockDataProvider.generateRomeGyms()
            filteredGyms = gyms
        }
        
        isLoading = false
    }
    
    // MARK: - Search
    func search() async {
        guard !searchQuery.isEmpty else {
            filteredGyms = gyms
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let location = locationService.currentLocation?.coordinate
            let results = try await gymsService.searchGyms(query: searchQuery, near: location)
            filteredGyms = results
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        searchQuery = ""
        filteredGyms = gyms
    }
    
    // MARK: - Filters
    func applyFilters() async {
        showFilters = false
        await loadGyms()
    }
    
    func clearFilters() {
        filters = GymFilters()
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
    
    // MARK: - Location
    func requestLocationPermission() {
        locationService.requestLocationPermission()
    }
    
    func centerOnUserLocation() {
        if let location = locationService.currentLocation {
            updateMapRegion(for: location.coordinate)
        } else {
            // Request location and update when available
            locationService.requestOneTimeLocation()
            // Fallback to Rome center if location not available
            let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
            updateMapRegion(for: romeCenter)
        }
    }
    
    // MARK: - Sorting
    func sortByDistance() {
        guard let userLocation = locationService.currentLocation else { return }
        
        filteredGyms.sort { gym1, gym2 in
            let distance1 = gym1.distance(from: userLocation)
            let distance2 = gym2.distance(from: userLocation)
            return distance1 < distance2
        }
    }
    
    func sortByPrice() {
        filteredGyms.sort { $0.pricePerHour < $1.pricePerHour }
    }
    
    func sortByRating() {
        filteredGyms.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
    }
}

