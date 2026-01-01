# Step 17: Quick Book, Single Session Rule, Extend Time - Summary

## Overview
Implemented three feature fixes before Groups/Chat feature:
- A) Quick Book UI Fix
- B) Single Active Session Rule + Cancel (No Refund)
- C) Check-In "Extend Time" Buttons

---

## A) QUICK BOOK UI FIX

### Problem
When there is NO active session, Home shows Quick Book but the text was wrong and didn't show recently booked gym info.

### Solution
The Quick Book section now properly displays:
- 3 duration cards (1h, 1.5h, 2h) with prices (€2/€3/€4)
- Last USER booking gym name
- Relative date (Today, Yesterday, X days ago)
- Gym address line
- Empty state with "Find Gyms" CTA if no previous user booking

### Changes

**HomeViewModel.swift:**
```swift
// New computed properties
var quickBookGym: Gym? {
    guard let booking = lastUserBooking else { return nil }
    return MockDataStore.shared.gymById(booking.gymId)
}

var quickBookAddress: String {
    quickBookGym?.address ?? lastUserBooking?.gymAddress ?? ""
}

var quickBookRelativeDate: String {
    guard let booking = lastUserBooking else { return "" }
    return formatRelativeDate(booking.startTime)
}
```

---

## B) SINGLE ACTIVE SESSION RULE + CANCEL (NO REFUND)

### Problem
Users could book multiple sessions simultaneously. No way to cancel an active session.

### Solution
1. **Block double bookings**: If user has an active session, any new booking attempt is blocked
2. **Cancel button**: Added to Active Session card on Home, cancels without refund

### Error Message
```
"You already have an active session. End or cancel it before booking another."
```

### Changes

**BookingServiceProtocol.swift:**
```swift
enum BookingServiceError: LocalizedError {
    // ... existing cases
    case activeSessionExists  // NEW
    
    var errorDescription: String? {
        case .activeSessionExists:
            return "You already have an active session. End or cancel it before booking another."
    }
}
```

**MockBookingService.swift:**
```swift
func createBooking(...) async throws -> BookingConfirmation {
    // SINGLE ACTIVE SESSION RULE: Check if user already has an active session
    if MockBookingStore.shared.hasActiveSession() {
        print("❌ BOOKING FLOW: Blocked - user already has an active session")
        throw BookingServiceError.activeSessionExists
    }
    // ... rest of booking flow
}
```

**MockBookingStore.swift:**
```swift
/// Whether user has an active session (for single active session rule)
func hasActiveSession(now: Date = Date()) -> Bool {
    return currentUserSession(now: now) != nil
}
```

**ActiveSessionSummaryCard.swift:**
- Added `onCancel` callback parameter
- Added "Cancel Session" button with red styling
- Confirmation alert: "Cancel session? No refund will be issued."

**HomeViewModel.swift:**
```swift
/// Cancel the active session (no refund)
func cancelActiveSession() {
    guard let booking = activeBooking else { return }
    MockBookingStore.shared.cancel(bookingId: booking.id)
    load()
}
```

**DashboardView.swift:**
- Added error alert for booking errors
- Pass `onCancel` callback to `ActiveSessionSummaryCard`

---

## C) CHECK-IN "EXTEND TIME" BUTTONS

### Problem
Active sessions needed ability to add time without booking a new session.

### Solution
When there is an active session on Check-in tab:
- Show 3 extend buttons: +30 min (€1), +60 min (€2), +90 min (€3)
- Debit wallet immediately
- Update booking duration and end time
- Sync with Home tab (both read same currentUserSession())
- Persist changes

### Changes

**MockBookingStore.swift:**
```swift
/// Errors that can occur when extending a booking
enum BookingExtensionError: LocalizedError {
    case bookingNotFound
    case notUserBooking
    case bookingCancelled
    case sessionEnded
    case insufficientFunds
}

/// Extends a booking by adding minutes to its duration.
func extend(bookingId: String, addMinutes: Int) throws -> Booking {
    guard let index = bookings.firstIndex(...) else {
        throw BookingExtensionError.bookingNotFound
    }
    
    var booking = bookings[index]
    
    // Validation checks...
    
    // Update duration and end time
    booking.duration += addMinutes
    booking.endTime = Calendar.current.date(byAdding: .minute, value: addMinutes, to: booking.endTime)!
    booking.updatedAt = Date()
    
    bookings[index] = booking
    save()
    
    return booking
}
```

**CheckInHomeView.swift:**
- Added `@State private var isExtending = false` for concurrent tap prevention
- Added `extendTimeSection()` with 3 buttons
- Added `handleExtend()` method:
  1. Check wallet balance
  2. Debit wallet
  3. Extend booking in store
  4. Update UI with success message

```swift
private func handleExtend(booking: Booking, minutes: Int, costCents: Int) async {
    guard !isExtending else { return }
    isExtending = true
    
    // Check wallet balance
    guard walletStore.balanceCents >= costCents else {
        throw BookingExtensionError.insufficientFunds
    }
    
    // Debit wallet
    try walletStore.applyDebitForBooking(
        amountCents: costCents,
        bookingRef: "\(booking.id)-ext",
        gymName: booking.gymName,
        gymId: booking.gymId
    )
    
    // Extend booking
    let updatedBooking = try MockBookingStore.shared.extend(
        bookingId: booking.id,
        addMinutes: minutes
    )
    
    currentSession = updatedBooking
    successMessage = "+\(minutes) minutes added!"
    
    isExtending = false
}
```

**ExtendTimeButton component:**
```swift
struct ExtendTimeButton: View {
    let minutes: Int
    let price: String
    let isDisabled: Bool
    let action: () async -> Void
}
```

---

## Files Modified

| File | Action |
|------|--------|
| `Core/Services/BookingServiceProtocol.swift` | Added `activeSessionExists` error |
| `Core/Services/Mock/MockBookingService.swift` | Added active session check |
| `Core/Mock/MockBookingStore.swift` | Added `hasActiveSession()`, `extend()`, `BookingExtensionError` |
| `ViewModels/HomeViewModel.swift` | Added Quick Book properties, `cancelActiveSession()` |
| `Views/Dashboard/Components/ActiveSessionSummaryCard.swift` | Added Cancel button with confirmation |
| `Views/Dashboard/DashboardView.swift` | Added error alert, pass cancel callback |
| `Views/CheckIn/CheckInHomeView.swift` | Added Extend Time section with buttons |

---

## Definition of Done Tests

### 1) No active session, but previous booking exists:
✅ Home Quick Book shows last booked gym + address + relative date on all 3 duration cards

### 2) Active session exists:
✅ Home shows Active Session with Cancel button
✅ Cancel Session works (no refund), session disappears everywhere

### 3) Booking block:
✅ While active session exists, any booking attempt shows error:
**"You already have an active session. End or cancel it before booking another."**

### 4) Check-in extend:
✅ Buttons appear only when active session exists
✅ Only one extension can run at once (isExtending state)
✅ Balance decreases by correct amount
✅ Booking duration increases and countdown increases
✅ Home and Check-in show the same updated remaining time

### 5) Persistence:
✅ After relaunch, extended duration remains
✅ After cancel, it remains cancelled and does not reappear as active

---

## Build Status: ✅ **BUILD SUCCEEDED**
