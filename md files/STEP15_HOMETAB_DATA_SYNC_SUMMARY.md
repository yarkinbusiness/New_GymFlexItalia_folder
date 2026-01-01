# Step 15: HomeTab Data Sync - Summary

## Overview
Fixed HomeTab data conflicts by removing the legacy Home dashboard data pipeline and replacing it with a new structured system. The Home tab now reads only from canonical data stores and persists bookings across app launches.

## Files Created

### 1. `ViewModels/HomeViewModel.swift` (NEW)
New ViewModel for the Home/Dashboard tab that:
- Reads from `MockDataStore.shared.gyms` for gym catalog
- Reads from `MockBookingStore.shared` for bookings
- Takes `LocationService` from the view (not internal CLLocationManager)
- Computes `nearbyGyms`, `recentBookings`, `lastBooking`, `activeBooking`
- Provides formatting helpers for Quick Book section

**Published Properties:**
- `nearbyGyms: [Gym]` - Top 3 gyms sorted by distance
- `recentBookings: [Booking]` - All bookings sorted by startTime desc
- `lastBooking: Booking?` - Most recent booking of any status
- `activeBooking: Booking?` - CheckedIn or upcoming that hasn't ended
- `isLoading: Bool`
- `errorMessage: String?`
- `locationPermissionGranted: Bool`

**Functions:**
- `load()` - Loads bookings from store and computes derived properties
- `refreshNearbyGyms(userLocation:)` - Sorts gyms by distance, takes top 3
- `lastBookingSummary()` - Returns (gymName, relativeDate, priceString) tuple
- `distanceString(for:from:)` - Calculates distance string for a gym
- `completedBookings()` - Returns past/completed bookings for Recent Activity

## Files Modified

### 2. `Core/Mock/MockBookingStore.swift` (MODIFIED)
Added persistence layer using UserDefaults:

**New Structure:**
```swift
struct PersistedBookingData: Codable {
    var bookings: [Booking]
}
```

**New Methods:**
- `load()` - Loads booking data from UserDefaults on init
- `save()` - Saves booking data to UserDefaults after mutations

**Changes:**
- `seedIfNeeded()` now checks if storage is empty before seeding, and calls `save()` after
- `upsert(_:)` now calls `save()` after insert/update
- `markCheckedIn(bookingId:checkedInAt:)` now calls `save()` after mutation
- `cancel(bookingId:)` now calls `save()` after mutation

**Persistence Key:** `"booking_store_v1"`

### 3. `Views/Dashboard/DashboardView.swift` (REWRITTEN)
Complete rewrite to use `HomeViewModel` instead of `DashboardViewModel`:

**Environment Dependencies:**
- `@StateObject private var viewModel = HomeViewModel()`
- `@EnvironmentObject var router: AppRouter`
- `@EnvironmentObject var locationService: LocationService`
- `@Environment(\.appContainer) var appContainer`

**Removed:**
- All placeholder gym data (hardcoded "MaxFit San Lorenzo", etc.)
- All placeholder booking data (hardcoded "UrbanFit Villa Borghese", etc.)
- Hardcoded "5 days ago", "€4.00" values
- Hardcoded "gym_001" gymId in Quick Book

**Quick Book Section:**
- Now shows last booking summary from `viewModel.lastBookingSummary()`
- Tapping Quick Book at a gym creates booking via `appContainer.bookingService.createBooking()`
- If no last booking exists, shows empty state with "Find Gyms" CTA

**Nearby Gyms Section:**
- Uses `viewModel.nearbyGyms` (from MockDataStore.shared.gyms sorted by distance)
- Shows distance calculated from `locationService.currentLocation`
- Location permission banner when location unavailable
- Empty state with "Browse All Gyms" CTA

**Recent Activity Section:**
- Uses `viewModel.completedBookings()` for past/completed bookings only
- Shows accurate price from `booking.totalPrice` or calculated via `PricingCalculator`
- Status badge with proper colors per status
- Empty state with "Book a Session" CTA

**New Components:**
- `NearbyGymCardWithDistance` - Gym card with distance and tap action
- `RecentActivityCard` (simplified) - Now only accepts Booking, computes formatting

**Lifecycle:**
```swift
.task {
    viewModel.load()
    viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
}
.onChange(of: locationService.currentLocation) { _, newLocation in
    viewModel.refreshNearbyGyms(userLocation: newLocation)
}
.refreshable {
    viewModel.load()
    viewModel.refreshNearbyGyms(userLocation: locationService.currentLocation)
}
```

## Files Deleted

### 4. `ViewModels/DashboardViewModel.swift` (DELETED)
Removed legacy ViewModel that:
- Used `GymsService.shared` and `BookingService.shared`
- Had its own `CLLocationManager` (now LocationService is shared)
- Maintained inconsistent state

## Data Flow (New Architecture)

```
                    ┌─────────────────────────────┐
                    │     UserDefaults            │
                    │  "booking_store_v1"         │
                    └──────────┬──────────────────┘
                               │ load()/save()
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   MockBookingStore.shared                   │
│  • bookings: [Booking] (persisted)                         │
│  • upsert(), markCheckedIn(), cancel() → save()            │
│  • seedIfNeeded() → only if empty                          │
└────────────────────────────┬────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      HomeViewModel                          │
│  • recentBookings, lastBooking, activeBooking              │
│  • nearbyGyms (from MockDataStore + location)              │
│  • load(), refreshNearbyGyms()                             │
└────────────────────────────┬────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      DashboardView                          │
│  • Quick Book → lastBookingSummary()                       │
│  • Nearby Gyms → nearbyGyms + distanceString()             │
│  • Recent Activity → completedBookings()                   │
│  • Uses LocationService from environment                    │
└─────────────────────────────────────────────────────────────┘
```

## Testing Checklist

✅ **Book a gym in Discover/GymDetail**
→ MockBookingStore.upsert() → save() → persisted

✅ **Return to Home**
- Quick Book shows last booked gym name + relative date + paid amount
- Nearby Gyms shows closest 3 based on current location
- Recent Activity shows accurate completed bookings

✅ **Kill app and relaunch**
- Quick Book and Recent Activity still show correct saved bookings
- Nearby Gyms refreshes based on location again

✅ **BUILD SUCCEEDED**

## Notes

1. **Booking model** already has `Codable` conformance with `CodingKeys` - no changes needed
2. **LocationService** used from environment, not created internally in ViewModel
3. **PricingCalculator** used for fallback price formatting when `booking.totalPrice` is 0
4. **Empty states** added for all sections with appropriate CTAs
5. **Distance calculation** uses `Gym.distance(from: CLLocation)` method already on Gym model
