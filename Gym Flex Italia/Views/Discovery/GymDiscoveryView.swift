//
//  GymDiscoveryView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI
import MapKit

/// Gym discovery view matching LED design
struct GymDiscoveryView: View {
    
    @StateObject private var viewModel = GymDiscoveryViewModel()
    @State private var selectedPriceFilter: String? = "All"
    @Environment(\.appContainer) private var appContainer
    
    let priceFilters = ["All", "€2/h", "€2.5/h", "€3/h", "€3.5/h", "€4/h"]
    
    var body: some View {
        NavigationStack {
            ZStack {
            // Adaptive background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Error message if present
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                    
                    // Header
                    headerSection
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.md)
                    
                    // Always-visible Map
                    mapViewSection
                        .frame(height: 300)
                        .padding(.bottom, Spacing.md)
                    
                    // Sticky Search Bar Section
                    Section(header: searchBarHeader) {
                        VStack(spacing: 0) {
                            // Price Filters
                            priceFilterSection
                                .padding(.top, Spacing.md)
                            
                            // Results Count
                            resultsCountSection
                                .padding(.top, Spacing.sm)
                            
                            // Gym List
                            gymListContent
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                LoadingOverlayView(message: "Finding gyms...")
            }
        }
        }
        .task {
            // Use injected service from AppContainer
            await viewModel.loadGyms(using: appContainer.gymService)
        }
        .onAppear {
            // Request location permission and center on user
            viewModel.requestLocationPermission()
            viewModel.centerOnUserLocation()
        }
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textHigh)
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textDim)
            }
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
        .padding(.horizontal, Spacing.md)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Discover")
                .font(AppFonts.h1)
                .foregroundColor(Color(.label))
            
            Text("Find the perfect gym near you")
                .font(AppFonts.bodySmall)
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Search Bar Header
    private var searchBarHeader: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textDim)
                
                TextField("Search by name or area...", text: $viewModel.searchQuery)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textHigh)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textDim)
                    }
                }
            }
            .padding(Spacing.md)
            .glassBackground(cornerRadius: CornerRadii.md)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color(.systemBackground).opacity(0.95)) // Opaque background for sticky header
    }
    
    // MARK: - Map View Section
    private var mapViewSection: some View {
        GymMapView(
            region: $viewModel.mapRegion,
            gyms: viewModel.filteredGyms,
            onGymSelected: { gym in
                viewModel.selectGym(gym)
            },
            showUserLocation: true
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadii.lg, style: .continuous))
        .padding(.horizontal, Spacing.md)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Gym List Content
    private var gymListContent: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(viewModel.filteredGyms) { gym in
                GymCard(gym: gym)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, 100) // Space for tab bar
    }
    
    // MARK: - Price Filter Section
    private var priceFilterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Filter by Price")
                .font(AppFonts.h5)
                .foregroundColor(Color(.label))
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(priceFilters, id: \.self) { filter in
                        Button {
                            selectedPriceFilter = filter
                            applyPriceFilter(filter)
                        } label: {
                            Text(filter)
                                .font(AppFonts.bodySmall)
                                .foregroundColor(
                                    selectedPriceFilter == filter
                                        ? AppColors.textHigh
                                        : AppColors.textDim
                                )
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    Group {
                                        if selectedPriceFilter == filter {
                                            AppGradients.primary
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .clipShape(Capsule())
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private func applyPriceFilter(_ filter: String) {
        guard filter != "All" else {
            viewModel.filteredGyms = viewModel.gyms
            return
        }
        
        // Extract price from filter (e.g., "€2/h" -> 2.0)
        let priceString = filter.replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "/h", with: "")
        guard let price = Double(priceString) else {
            return
        }
        
        viewModel.filteredGyms = viewModel.gyms.filter { gym in
            abs(gym.pricePerHour - price) < 0.1 // Allow small floating point differences
        }
    }
    
    // MARK: - Results Count Section
    private var resultsCountSection: some View {
        HStack {
            Text("\(viewModel.filteredGyms.count) Gyms Found")
                .font(AppFonts.bodySmall)
                .foregroundColor(Color(.secondaryLabel))
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
    }
    
}

// MARK: - Gym Card
struct GymCard: View {
    let gym: Gym
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(gym.name)
                        .font(AppFonts.h4)
                        .foregroundColor(AppColors.textHigh)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                        Text(gym.address)
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.textDim)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.warning)
                        Text(String(format: "%.1f", gym.rating ?? 0))
                            .font(AppFonts.bodySmall)
                        Text("•")
                            .foregroundColor(AppColors.textDim)
                        Text("1.2 km")
                            .font(AppFonts.bodySmall)
                    }
                    .foregroundColor(AppColors.textDim)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("€\(Int(gym.pricePerHour))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.brand)
                    + Text("/hour")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(AppColors.textHigh)
                }
            }
            
            // Amenities
            HStack(spacing: Spacing.md) {
                AmenityChip(icon: "wifi", label: "WiFi")
                AmenityChip(icon: "drop.fill", label: "Showers")
                AmenityChip(icon: "lock.fill", label: "Lockers")
            }
            
            // Book Button
            NavigationLink(destination: GymDetailView(gymId: gym.id)) {
                Text("Book Now")
                    .font(AppFonts.label)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(AppGradients.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md))
            }
            .simultaneousGesture(TapGesture().onEnded {
                DemoTapLogger.log("GymCard.BookNow", context: "gymId: \(gym.id)")
            })
        }
        .padding(Spacing.md)
        .glassBackground(cornerRadius: CornerRadii.lg)
    }
}

// MARK: - Amenity Chip
struct AmenityChip: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(label)
                .font(AppFonts.caption)
        }
        .foregroundColor(AppColors.textDim)
    }
}

#Preview {
    GymDiscoveryView()
        .environment(\.appContainer, .demo())
}
