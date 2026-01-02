# STEP 33 — Discovery Search, Filters & Map

**Date:** 2026-01-02  
**Build Status:** ✅ BUILD SUCCEEDED  
**Behavior Change:** Enhanced UI only (no backend changes)

---

## Overview

Enhanced the Discover tab with comprehensive search, filters, and map view. All features use the canonical `MockDataStore` gym data — list and map always show the same filtered results.

---

## PART A — Discovery Filter Model

### File Created
`Core/Discovery/DiscoveryFilter.swift`

### Features
```swift
struct DiscoveryFilter {
    var searchText: String           // Name/address search
    var maxDistanceKm: Double?       // Distance filter (nil = no limit)
    var priceRange: ClosedRange<Double>?  // Price filter
    var requiredAmenities: Set<Amenity>   // Must-have amenities
    var requiredEquipment: Set<Equipment> // Must-have equipment
    var minRating: Double?           // Minimum rating
    
    var hasActiveFilters: Bool       // Any filter active?
    var activeFilterCount: Int       // For badge display
    mutating func reset()            // Clear all filters
}
```

### Preset Filters
- `.default()` — No constraints
- `.nearby()` — Within 5km
- `.budget()` — €0-3/hour
- `.premium()` — 4.5+ rating

---

## PART B — ViewModel Upgrade

### File Modified
`ViewModels/GymDiscoveryViewModel.swift`

### Changes
| Property | Description |
|----------|-------------|
| `allGyms` | All gyms from canonical source |
| `filteredGyms` | Filtered results (drives list AND map) |
| `filter` | Current filter settings |
| `viewMode` | `.list` or `.map` |
| `showFilters` | Filter sheet visibility |

### Filtering Pipeline
```
1. Search text (name + address + city + description)
2. Distance (if location available)
3. Price range
4. Required amenities
5. Required equipment
6. Minimum rating
```

### Guardrail
```swift
#if DEBUG
assert(filteredIds.isSubset(of: allIds), "filteredGyms must be subset of allGyms")
#endif
```

---

## PART C — Discover UI

### File Modified
`Views/Discovery/GymDiscoveryView.swift`

### Features Added
- **Search bar** with clear button
- **Filter button** with active filter badge
- **View mode toggle** (List / Map)
- **Results count** with clear filters option
- **Empty state** when no results
- **Enhanced gym cards** with distance, rating

### File Created
`Views/Discovery/DiscoveryFilterSheet.swift`

### Filter Sheet Sections
| Section | Controls |
|---------|----------|
| Distance | Toggle + slider (1-20 km) |
| Price | Toggle + min/max sliders |
| Rating | Toggle + slider (1-5 stars) |
| Amenities | Multi-select list |
| Reset | Reset all button |

---

## PART D — Map View

### File (Existing)
`Views/Discovery/GymMapView.swift`

The existing GymMapView already:
- Shows pins for each gym
- Uses MapKit with branded markers
- Handles pin selection
- Navigates to GymDetailView on tap

### Integration
- Map and list share the SAME `filteredGyms` array
- Filter changes update both views simultaneously
- User location button available

---

## PART E — Guardrails

### DEBUG Assertions
| Check | Location |
|-------|----------|
| `filteredGyms ⊆ allGyms` | GymDiscoveryViewModel |
| Distance filter ignored if no location | applyFilters() |

### Safety Features
- Distance filter only applies when location available
- Search is case-insensitive
- Empty search returns all gyms
- Filter sheet has Reset button

---

## Files Summary

### Created (2 files)
```
Core/Discovery/DiscoveryFilter.swift
Views/Discovery/DiscoveryFilterSheet.swift
```

### Modified (2 files)
```
ViewModels/GymDiscoveryViewModel.swift
Views/Discovery/GymDiscoveryView.swift
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    MockDataStore.shared                      │
│                  (SINGLE SOURCE OF TRUTH)                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   GymServiceProtocol │
              │  (MockGymService)    │
              └──────────┬──────────┘
                         │ fetchGyms()
                         ▼
              ┌─────────────────────┐
              │ GymDiscoveryViewModel│
              │                     │
              │  allGyms: [Gym]     │
              │  filter: DiscoveryFilter
              │       ↓             │
              │  applyFilters()     │
              │       ↓             │
              │  filteredGyms: [Gym]│
              └──────────┬──────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    List View       Map View       Filter Sheet
    (cards)         (pins)         (controls)
```

---

## Verification Checklist

| Test | Expected | Status |
|------|----------|--------|
| Search narrows list | ✅ | ✅ |
| Search narrows map | ✅ | ✅ |
| Distance filter works | ✅ (with location) | ✅ |
| Price filter works | ✅ | ✅ |
| Amenity filter works | ✅ | ✅ |
| Map/list match | Same filteredGyms | ✅ |
| Tap gym → detail | Opens GymDetailView | ✅ |
| BUILD SUCCEEDED | ✅ | ✅ |

---

## Usage

### From User Perspective
1. Open Discover tab
2. Type in search bar to filter by name/location
3. Tap filter button to open filter sheet
4. Adjust distance, price, rating, amenities
5. Tap Apply to see filtered results
6. Toggle between List and Map views
7. Tap any gym to see details and book

### Programmatic
```swift
// Set filter programmatically
viewModel.filter = .nearby()

// Apply search
viewModel.filter.searchText = "Colosseo"

// Clear all
viewModel.clearFilters()
```
