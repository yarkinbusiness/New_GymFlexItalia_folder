//
//  GymDiscoveryView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI
import MapKit

/// Gym discovery view with search, filters, list, and map
struct GymDiscoveryView: View {
    
    @StateObject private var viewModel = GymDiscoveryViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.appContainer) private var appContainer
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search and filters
                headerSection
                
                // View mode toggle
                viewModeToggle
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                
                // Error message if present
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                
                // Content based on view mode
                Group {
                    switch viewModel.viewMode {
                    case .list:
                        listView
                    case .map:
                        mapView
                    }
                }
            }
            
            // Loading overlay
            if viewModel.isLoading {
                LoadingOverlayView(message: "Finding gyms...")
            }
        }
        .sheet(isPresented: $viewModel.showFilters) {
            DiscoveryFilterSheet(filter: $viewModel.filter)
        }
        .task {
            await viewModel.loadGyms(using: appContainer.gymService)
        }
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Title
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover")
                        .font(AppFonts.h1)
                        .foregroundColor(.primary)
                    
                    Text("Find the perfect gym near you")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            
            // Search bar with filter button
            searchBarSection
        }
    }
    
    // MARK: - Search Bar Section
    
    private var searchBarSection: some View {
        HStack(spacing: Spacing.sm) {
            // Search field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search gyms...", text: $viewModel.filter.searchText)
                    .font(AppFonts.body)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                
                if viewModel.filter.hasSearchText {
                    Button {
                        viewModel.filter.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.md)
            
            // Filter button
            Button {
                viewModel.showFilters = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.filter.hasActiveFilters ? .white : AppColors.brand)
                        .frame(width: 48, height: 48)
                        .background(
                            viewModel.filter.hasActiveFilters
                                ? AnyShapeStyle(AppGradients.primary)
                                : AnyShapeStyle(Color(.secondarySystemBackground))
                        )
                        .cornerRadius(CornerRadii.md)
                    
                    // Filter count badge
                    if viewModel.filter.activeFilterCount > 0 {
                        Text("\(viewModel.filter.activeFilterCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(AppColors.danger)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(GymDiscoveryViewModel.ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.viewMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        Text(mode.title)
                            .font(AppFonts.label)
                    }
                    .foregroundColor(viewModel.viewMode == mode ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        viewModel.viewMode == mode
                            ? AnyShapeStyle(AppGradients.primary)
                            : AnyShapeStyle(Color.clear)
                    )
                    .cornerRadius(CornerRadii.sm)
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(CornerRadii.md)
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                // Results count
                HStack {
                    Text("\(viewModel.filteredGyms.count) gyms found")
                        .font(AppFonts.bodySmall)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewModel.filter.hasActiveFilters {
                        Button {
                            viewModel.clearFilters()
                        } label: {
                            Text("Clear filters")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.brand)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                
                // Gym cards
                ForEach(viewModel.filteredGyms) { gym in
                    GymDiscoveryCard(
                        gym: gym,
                        distance: viewModel.formattedDistance(for: gym),
                        onTap: {
                            router.pushGymDetail(gymId: gym.id)
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                }
                
                // Empty state
                if viewModel.filteredGyms.isEmpty && !viewModel.isLoading {
                    emptyState
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        GymMapView(
            region: $viewModel.mapRegion,
            gyms: viewModel.filteredGyms,
            onGymSelected: { gym in
                viewModel.selectGym(gym)
                router.pushGymDetail(gymId: gym.id)
            },
            showUserLocation: true
        )
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .topLeading) {
            // Gym count badge
            HStack(spacing: 6) {
                Image(systemName: "building.2")
                    .font(.system(size: 12))
                Text("\(viewModel.filteredGyms.count) gyms")
                    .font(AppFonts.caption)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadii.pill)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.leading, Spacing.md)
            .padding(.top, Spacing.md)
        }
        .overlay(alignment: .topTrailing) {
            // User location button
            Button {
                viewModel.centerOnUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.brand)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .padding(.trailing, Spacing.md)
            .padding(.top, Spacing.md)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No gyms found")
                .font(AppFonts.h3)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search or filters")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if viewModel.filter.hasActiveFilters || viewModel.filter.hasSearchText {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear All Filters")
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradients.primary)
                        .cornerRadius(CornerRadii.md)
                }
            }
        }
        .padding(Spacing.xl)
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(AppFonts.bodySmall)
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(CornerRadii.md)
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Gym Discovery Card

struct GymDiscoveryCard: View {
    let gym: Gym
    let distance: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack(alignment: .top) {
                    // Gym icon
                    ZStack {
                        Circle()
                            .fill(AppGradients.primary)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gym.name)
                            .font(AppFonts.h4)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11))
                            Text(gym.address)
                                .lineLimit(1)
                        }
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("€\(String(format: "%.2f", gym.pricePerHour))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.brand)
                        Text("/hour")
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Info row
                HStack(spacing: Spacing.lg) {
                    // Rating
                    if let rating = gym.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                        }
                        .font(AppFonts.bodySmall)
                    }
                    
                    // Distance
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                            Text(distance)
                        }
                        .font(AppFonts.bodySmall)
                        .foregroundColor(.secondary)
                    }
                    // Review count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                        Text("\(gym.reviewCount) reviews")
                    }
                    .font(AppFonts.bodySmall)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Amenities
                if !gym.amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(gym.amenities.prefix(5), id: \.self) { amenity in
                                HStack(spacing: 4) {
                                    Image(systemName: amenity.icon)
                                        .font(.system(size: 10))
                                    Text(amenity.displayName)
                                        .font(AppFonts.caption)
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemFill))
                                .cornerRadius(CornerRadii.sm)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GymDiscoveryView()
        .environmentObject(AppRouter())
        .environment(\.appContainer, .demo())
}
