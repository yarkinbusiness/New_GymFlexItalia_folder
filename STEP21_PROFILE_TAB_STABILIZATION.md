# Step 21: Profile Tab Stabilization - Summary

## Overview
Stabilized and modernized the Profile tab to use canonical services/stores and removed legacy/placeholder data sources.

---

## PART A — ProfileViewModel Refactor

### ProfileViewModel.swift (Rewritten)

**Published State:**
```swift
@Published var profile: Profile?
@Published var isLoading = false
@Published var errorMessage: String?
@Published var walletBalanceCents: Int?
@Published var upcomingCount: Int = 0
@Published var pastCount: Int = 0
@Published var lastBookingSummary: String?
```

**Key Methods:**
```swift
func load(using container: AppContainer) async
func retry(using container: AppContainer) async
func refresh(using container: AppContainer) async
```

**Implementation:**
1. Fetches profile via `container.profileService.fetchCurrentProfile()`
2. Reads wallet balance from `WalletStore.shared.balanceCents` (canonical source)
3. Computes booking stats from `MockBookingStore.shared`:
   - `upcomingCount` = user bookings with endTime > now AND not cancelled
   - `pastCount` = user bookings with endTime <= now OR completed/cancelled
   - `lastBookingSummary` = most recent user booking's gymName + date

**Removed:**
- `ProfileService.shared` singleton
- `BookingService.shared` singleton
- `AuthService.shared` singleton

---

## PART B — ProfileView Refactor

### ProfileView.swift (Rewritten)

**Dependencies:**
```swift
@StateObject private var viewModel = ProfileViewModel()
@Environment(\.appContainer) var appContainer
@EnvironmentObject var router: AppRouter
```

**UI States:**
1. **Loading:** Shows spinner when `isLoading && profile == nil`
2. **Error:** Shows error message + Retry button when `errorMessage != nil && profile == nil`
3. **Content:** Full profile view when data loads successfully

**New Sections:**
- **Wallet Summary:** Shows `formattedWalletBalance` from WalletStore, taps → Wallet screen
- **Booking Summary:** Shows `upcomingCount`, `pastCount`, `lastBookingSummary` from MockBookingStore

**Removed:**
- `AuthService.shared` reference
- `paymentMethodsSection` (static placeholder data)
- Old `bookingHistorySection` with static placeholder

**Navigation (preserved):**
- Edit Profile → `router.pushEditProfile()`
- Settings → `router.pushSettings()` (if present)
- My Bookings → `router.pushBookingHistory()`
- Wallet → `router.pushWallet()`

---

## PART C — Canonical Source Consistency

### Wallet Balance
```swift
// ProfileViewModel reads from WalletStore (same as Wallet screen)
walletBalanceCents = WalletStore.shared.balanceCents

// Also observes changes via Combine
WalletStore.shared.$balanceCents
    .receive(on: DispatchQueue.main)
    .sink { [weak self] cents in
        self?.walletBalanceCents = cents
    }
```

### Booking Statistics
```swift
// Uses MockBookingStore helper methods
let userBookings = MockBookingStore.shared.userBookings() // Only user bookings
let lastBooking = MockBookingStore.shared.lastUserBooking()

// isUserBooking check: booking.id.hasPrefix("booking_GF-")
// This excludes seeded demo data from stats
```

---

## Files Modified

| File | Changes |
|------|---------|
| `ViewModels/ProfileViewModel.swift` | Rewrote to use AppContainer DI, WalletStore, MockBookingStore |
| `Views/Profile/ProfileView.swift` | Rewrote to use DI, added loading/error states, wallet/booking summaries |

---

## Definition of Done Tests

### ✅ Fresh launch shows profile data
- Profile shows loading spinner initially
- Then renders profile name/email from profileService

### ✅ Wallet balance matches Wallet screen
- Both use `WalletStore.shared.balanceCents`
- Profile observes changes via Combine

### ✅ Booking counts use canonical store
- Uses `MockBookingStore.shared.userBookings()`
- Only counts user bookings (prefix `booking_GF-`)
- Seeded demo bookings ignored

### ✅ Make a booking → Profile updates
- `upcomingCount` increases after new booking
- `lastBookingSummary` updates with new gym name + date

### ✅ End/cancel session → Counts update
- After refresh, `pastCount` increases
- `upcomingCount` decreases

### ✅ Error state shows Retry
- If profile fetch fails, shows error view
- Retry button reloads data

---

## Removed Legacy Dependencies

| Removed | Replaced With |
|---------|---------------|
| `ProfileService.shared` | `container.profileService` |
| `BookingService.shared` | `MockBookingStore.shared` |
| `AuthService.shared` | Removed (not needed in Profile) |
| Static payment methods | Removed section entirely |

---

## Consistency Confirmations

### ✅ Wallet balance source
ProfileView uses `WalletStore.shared.balanceCents` — same canonical source as:
- `WalletFullView`
- `WalletButtonView` on Home

### ✅ Booking stats source
ProfileView uses `MockBookingStore.shared.userBookings()` — same canonical source as:
- `CheckInView` (via `currentUserSession`)
- `HomeView` (via `currentUserSession`)

### ✅ Seeded bookings excluded
User booking detection: `booking.id.hasPrefix("booking_GF-")`
This matches logic in Home/Check-in tabs.

---

## Build Status: ✅ **BUILD SUCCEEDED**
