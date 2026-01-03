# UX IMPROVEMENT — Session End UX (Active Session + Check-in + Recent Activity)

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

Implemented clear transitions from "Ongoing" to "Ended" when a session countdown reaches 0:
- Check-in tab shows "Session Ended" state with CTAs
- Home Active Session disappears, Quick Book returns
- Recent Activity shows ended booking (not as "Ongoing")
- No QR or Extend Time for ended sessions

---

## Files Modified (2)

| File | Changes |
|------|---------|
| `Core/Mock/MockBookingStore.swift` | Added `isSessionActive()` and `isSessionEnded()` helpers |
| `Views/CheckIn/CheckInHomeView.swift` | Added Session Ended panel, conditional UI |

---

## PART A — Single Source of Truth Helpers

**Added to `MockBookingStore.swift`:**

```swift
// MARK: - Session State Helpers (Single Source of Truth)

/// Check if a session is currently active (not cancelled, not ended)
func isSessionActive(_ booking: Booking, now: Date = Date()) -> Bool {
    return booking.status != .cancelled && booking.endTime > now
}

/// Check if a session has ended (time expired, not cancelled)
func isSessionEnded(_ booking: Booking, now: Date = Date()) -> Bool {
    return booking.status != .cancelled && booking.endTime <= now
}
```

All UI now uses these consistent rules.

---

## PART B — Check-in Tab Behavior

### Active Session (`isSessionActive == true`)
Shows:
- ✅ Countdown timer
- ✅ Extend Time buttons
- ✅ QR code
- ✅ Booking details
- ✅ Check-in button

### Session Ended (`isSessionEnded == true`)
Shows:
- ✅ "Session Ended" header
- ✅ "Ended" status badge (gray)
- ✅ Session Complete panel with checkmark
- ✅ Summary (duration, cost, end time)
- ✅ "Book Again" primary CTA → Discover
- ✅ "View History" secondary CTA → Booking History

Does NOT show:
- ❌ QR code
- ❌ Extend Time buttons
- ❌ Countdown (shows "Session Ended" instead)

### Automatic Refresh on End
Timer tick detects `session.endTime <= now` and triggers `loadSession()` to refresh UI.

---

## PART C — Home Tab Behavior

### Active Session
- `activeBooking` is set via `currentUserSession()` (filters `endTime > now`)
- Active Session card is displayed

### Session Ended
- `currentUserSession()` returns `nil` (since `endTime <= now`)
- `activeBooking` becomes `nil`
- Quick Book section returns

### Recent Activity
- Ended booking appears at top of completed list
- NOT shown as "Ongoing" (since `activeBooking == nil`)
- `isOngoing: false` in `RecentActivityItem`

---

## PART D — Booking History

- Uses same `isSessionEnded` logic via existing filters
- Ended sessions appear in Past list
- No "Ongoing" label for ended sessions

---

## Session Ended Panel UI

```
┌─────────────────────────────────────┐
│      ✓ Session Complete             │
│                                     │
│  Thanks for training at FitLab!     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Duration          60 minutes       │
│  Cost              €10.00           │
│  Ended             Jan 3, 3:22 AM   │
└─────────────────────────────────────┘

  ┌─────────────────────────────────┐
  │          Book Again             │  ← Primary
  └─────────────────────────────────┘
  ┌─────────────────────────────────┐
  │         View History            │  ← Secondary
  └─────────────────────────────────┘
```

---

## Manual Test Steps

1. **Book a short session** (or set endTime close to now for testing)
2. **Watch countdown reach 0:**
   - Check-in tab switches to "Session Ended" state
   - QR code disappears
   - Extend Time buttons disappear
   - "Book Again" and "View History" buttons appear
3. **Check Home tab:**
   - Active Session card disappears
   - Quick Book section returns
   - Recent Activity shows ended booking at top (not "Ongoing")
4. **Check Booking History:**
   - Ended booking appears in Past Sessions list
5. **BUILD SUCCEEDED**

---

## Verification Checklist

| Check | Status |
|-------|--------|
| `isSessionActive()` added to MockBookingStore | ✅ |
| `isSessionEnded()` added to MockBookingStore | ✅ |
| Check-in: QR hidden when ended | ✅ |
| Check-in: Extend Time hidden when ended | ✅ |
| Check-in: Session Ended panel shown | ✅ |
| Check-in: "Book Again" navigates to Discover | ✅ |
| Check-in: "View History" navigates to History | ✅ |
| Home: Active Session disappears when ended | ✅ |
| Home: Quick Book returns when ended | ✅ |
| Recent Activity: No "Ongoing" for ended | ✅ |
| Auto-refresh on countdown end | ✅ |
| BUILD SUCCEEDED | ✅ |
