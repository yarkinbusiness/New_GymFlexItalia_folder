# UX FIX — Home > Recent Activity (Canonical Data + Ongoing State)

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

Fixed the Recent Activity section on the Home tab to:
1. Use canonical data from `MockBookingStore`
2. Show active session at top with "Ongoing" label
3. Remove static/mock activity data
4. Prevent duplicate or stale entries

---

## Changes Made

### HomeViewModel.swift

**Added:**
```swift
/// Activity item for Recent Activity section
struct RecentActivityItem: Identifiable {
    let id: String
    let booking: Booking
    let isOngoing: Bool
}

/// Get activity items for Recent Activity section
func recentActivityItems() -> [RecentActivityItem]
```

**Logic:**
1. If `activeBooking` exists → Insert at index 0 with `isOngoing: true`
2. Append completed bookings (sorted by endTime desc)
3. Exclude active session from completed list (no duplicates)
4. Limit to 4 items total (3 completed if active exists)

**Removed:**
- `completedBookings()` method (replaced with `recentActivityItems()`)

---

### DashboardView.swift

**Recent Activity Section:**
- Changed from `completedBookings.prefix(3)` to `recentActivityItems()`
- Updated "See All" to navigate to Booking History (not Profile)
- Updated empty state text: "Your recent activity will appear here."

**RecentActivityCard:**
- Added `isOngoing: Bool` parameter
- When `isOngoing == true`:
  - Shows green pulsing dot next to gym name
  - Text weight is bold
  - Background has subtle green tint
  - Border has green stroke
  - Badge shows "Ongoing" instead of status
  - Date shows "Now" instead of calculated date

---

## Data Sources (Canonical)

| Data | Source |
|------|--------|
| Active session | `MockBookingStore.currentUserSession()` |
| Recent bookings | `MockBookingStore.shared.allBookings()` filtered |
| Completed filter | `booking.endTime < now OR booking.status == .completed` |

**NOT used:**
- Static arrays ❌
- Demo/fake data ❌
- Local activity models ❌

---

## Files Modified (2)

| File | Changes |
|------|---------|
| `ViewModels/HomeViewModel.swift` | Added `RecentActivityItem` struct, `recentActivityItems()` method |
| `Views/Dashboard/DashboardView.swift` | Updated section to use new method, updated `RecentActivityCard` |

---

## Visual Changes

### Ongoing Session Card
- Slightly green-tinted background
- Subtle green border
- Green dot indicator next to gym name
- Bold gym name
- "Ongoing" badge (green)
- "Now" for date

### Completed Session Card (unchanged layout)
- Normal background
- Status badge (Completed, Cancelled, etc.)
- Relative date (Today, Yesterday, or date)

---

## Manual Test Steps

1. **No active session:**
   - Recent Activity shows completed bookings only
   - Shows up to 4 past sessions

2. **Book a session:**
   - New session appears at TOP of Recent Activity
   - Shows "Ongoing" badge
   - Shows "Now" for date
   - Green visual indicators

3. **Session ends:**
   - Card moves to normal completed style
   - Badge changes to "Completed"
   - No duplicate entries

4. **Empty state:**
   - If no sessions: "Your recent activity will appear here."
   - "Book a Session" button navigates to Discover

---

## Verification Checklist

| Check | Status |
|-------|--------|
| Uses canonical data from MockBookingStore | ✅ |
| Active session shows at top | ✅ |
| Active session has "Ongoing" label | ✅ |
| No duplicates (active not in completed) | ✅ |
| Completed sorted by most recent | ✅ |
| Empty state shows correct message | ✅ |
| No static/mock data | ✅ |
| Layout unchanged (only styling for ongoing) | ✅ |
| BUILD SUCCEEDED | ✅ |
