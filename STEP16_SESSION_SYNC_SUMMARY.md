# Step 16: HomeTab + Check-in Session Sync - Summary

## Overview
Fixed the logic conflict between HomeTab "Active Session" and the Check-in tab by implementing a single shared selection rule in `MockBookingStore`. Both Home and Check-in now use the exact same `currentUserSession()` logic.

## Key Changes

### Root Cause Fixes
1. **Seed/demo bookings were treated as real user bookings** → Added `isUserBooking()` helper
2. **Home and Check-in used different selection rules** → Created single `currentUserSession()` method
3. **Upcoming seed bookings caused phantom active sessions** → Removed ALL upcoming bookings from seed data

---

## PART A — User Booking Detection

### New Methods in `MockBookingStore`:

```swift
/// Determines if a booking is a user-created booking (not seeded demo data)
/// User bookings have IDs starting with "booking_GF-" (created via MockBookingService)
func isUserBooking(_ booking: Booking) -> Bool {
    return booking.id.hasPrefix("booking_GF-")
}

/// Whether any user-created bookings exist in the store
var hasUserBookings: Bool {
    bookings.contains(where: isUserBooking)
}

/// Returns only user-created bookings (not seeded demo data)
func userBookings() -> [Booking]
```

### Seed Booking Changes:
- Seed booking IDs changed from `booking_completed_XXX` to `booking_seed_completed_XXX`
- All seed bookings now have `checkinCode: nil` and `qrCodeData: nil`
- **REMOVED** all 3 upcoming seed bookings - seeds are now ONLY past/completed/cancelled

---

## PART B — Shared Session Selection Logic

### The Single Source of Truth:

```swift
/// Returns the current active user session.
/// This is THE shared selection rule used by BOTH Home and Check-in tabs.
///
/// Selection rules:
/// - ONLY considers user bookings (isUserBooking == true)
/// - Excludes cancelled bookings
/// - Session end time must be > now (not yet ended)
/// - Returns the booking with the earliest endTime (currently running or soonest ending)
///
/// Returns nil if user has not booked or all sessions have ended.
func currentUserSession(now: Date = Date()) -> Booking?
```

### Additional Methods:
- `nextUserSession()` - Next upcoming user booking (startTime > now)
- `lastUserBooking()` - Most recent user booking (for Quick Book display)
- `upcomingUserBookings()` - All upcoming user bookings

---

## PART C — HomeViewModel Updates

### Changes:
- `activeBooking` now uses `MockBookingStore.shared.currentUserSession()`
- `lastBooking` renamed to `lastUserBooking` (only user bookings, not seeds)
- Added computed properties:
  - `showActiveSession: Bool` - whether to show Active Session card
  - `showQuickBook: Bool` - whether to show Quick Book section

### Logic:
```swift
func load() {
    // IMPORTANT: Use shared currentUserSession() for active session
    // This is THE shared selection logic - same as Check-in tab uses
    activeBooking = bookingStore.currentUserSession()
    
    // Last USER booking (for Quick Book display when no active session)
    lastUserBooking = bookingStore.lastUserBooking()
}
```

---

## PART D — CheckInHomeView Updates

### Complete Rewrite:
- Removed `@StateObject private var viewModel = BookingHistoryViewModel()`
- Now uses `@State private var currentSession: Booking?`
- Loads session via `MockBookingStore.shared.currentUserSession()`

### Key Changes:
```swift
/// Load current session using SHARED currentUserSession() logic
private func loadSession() async {
    // IMPORTANT: Use the SAME shared selection logic as HomeViewModel
    currentSession = MockBookingStore.shared.currentUserSession()
    
    // Get additional upcoming user bookings (excluding current session)
    let allUpcoming = MockBookingStore.shared.upcomingUserBookings()
    // ...
}
```

### Empty State:
When `currentSession == nil`:
- Shows "No Active Session"
- Shows "Book a gym session to get your check-in QR code"
- Shows "Find Gyms" button

---

## PART E — QR Code Location

### Rule:
- **QR code visible ONLY on Check-in tab**
- Home's "View QR Code" button switches to Check-in tab (does not display QR inline)

This was already correct - `ActiveSessionSummaryCard` calls `onViewQRCode` which triggers `router.switchToTab(.checkIn)`.

---

## Files Modified

| File | Action |
|------|--------|
| `Core/Mock/MockBookingStore.swift` | **Rewritten** - Added user booking detection, shared currentUserSession(), removed upcoming seeds |
| `ViewModels/HomeViewModel.swift` | **Rewritten** - Uses currentUserSession(), lastUserBooking |
| `Views/Dashboard/DashboardView.swift` | **Modified** - Changed lastBooking to lastUserBooking |
| `Views/CheckIn/CheckInHomeView.swift` | **Rewritten** - Uses currentUserSession() directly |

---

## Seed Booking Changes

### REMOVED (no longer seeded):
- `booking_upcoming_001` (tomorrow morning)
- `booking_upcoming_002` (day after tomorrow)
- `booking_upcoming_fail_003` (next week)

### KEPT (all past/completed):
- `booking_seed_completed_001` through `booking_seed_completed_008` (all 2+ days ago, completed)
- `booking_seed_cancelled_001` (5 days ago, cancelled)

### All Seed Bookings Now Have:
- `checkinCode: nil`
- `qrCodeData: nil`
- IDs starting with `booking_seed_` (not `booking_GF-`)

---

## Testing Checklist

### A) Fresh install / clear UserDefaults:
- ✅ Home shows Quick Book (not Active Session)
- ✅ Check-in shows "No Active Session"

### B) Book a session from Discover:
- ✅ Home shows Active Session for that booked gym
- ✅ Check-in shows the SAME gym + QR for the same bookingRef/checkInCode
- ✅ QR is NOT shown on Home, only in Check-in

### C) Kill app and relaunch:
- ✅ If session is still active (endAt > now), it still appears
- ✅ If session ended, Home returns to Quick Book and Check-in shows no session

---

## Selection Logic Flow

```
                User books a session
                        │
                        ▼
              MockBookingService.createBooking()
                        │
                        ▼
              Booking ID: "booking_GF-XXXXXX"
              checkInCode: "CHK-XXXXXX"
                        │
                        ▼
              MockBookingStore.upsert() → save()
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              MockBookingStore.currentUserSession()          │
│                                                             │
│  1. Filter: isUserBooking (id.hasPrefix("booking_GF-"))    │
│  2. Filter: status != .cancelled                           │
│  3. Filter: endTime > now                                  │
│  4. Sort: by endTime ascending                             │
│  5. Return: first (earliest ending)                        │
└─────────────────────────────┬───────────────────────────────┘
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
     HomeViewModel.load()          CheckInHomeView.loadSession()
              │                               │
              ▼                               ▼
     activeBooking = session       currentSession = session
              │                               │
              ▼                               ▼
   ActiveSessionSummaryCard      qrCodeCard + countdownSection
        (no QR inline)                 (shows QR code)
```

---

## Build Status: ✅ **BUILD SUCCEEDED**
