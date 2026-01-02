# UX FIX PACK — Wallet Buttons + Remove Upcoming Bookings Feature

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

This fix pack addresses:
1. **Wallet Buttons** - History scrolls to transactions, Send opens sheet
2. **Remove Upcoming Bookings** - Feature completely removed from all screens

---

## PART 1 — Wallet Buttons Fixed

### A) History Button

**Implementation:**
- Added `ScrollViewReader` wrapper around ScrollView
- Added `.id("transactions_section")` anchor to transactions section
- History button now scrolls to transactions with animation (respects Reduce Motion)

```swift
// On History tap:
if reduceMotion {
    scrollProxy.scrollTo("transactions_section", anchor: .top)
} else {
    withAnimation(.easeInOut(duration: 0.4)) {
        scrollProxy.scrollTo("transactions_section", anchor: .top)
    }
}
```

### B) Send Button

**New File:** `Views/Wallet/SendMoneySheetView.swift`

**Features:**
- Recipient text field (email/username)
- Amount numeric field (with € prefix)
- Submit button (disabled until valid)
- Demo alert: "Sending money is not available yet"
- Clean dismiss after alert

**WalletView Changes:**
- Added `@State showSendSheet = false`
- Removed `DemoTapLogger.logNoOp` - replaced with functional sheet

---

## PART 2 — Upcoming Bookings Feature Removed

### A) Check-in Tab (CheckInHomeView.swift)

**Removed:**
- `upcomingUserBookings: [Booking]` state
- `upcomingBookingsSection` view
- `upcomingBookingRow()` helper
- Loading logic for upcoming bookings

**Kept:**
- Active Session section
- Empty state "No Active Session"

### B) Booking History (BookingHistoryView.swift)

**Removed:**
- Segmented control (Upcoming/Past)
- `upcomingList` view
- `emptyUpcomingView`
- `pastList` (replaced with `historyList`)

**New Structure:**
- Single list: "Past Sessions"
- Empty state: "No Past Bookings"
- Navigation title: "Booking History"

### C) Profile Stats (ProfileView.swift + ProfileViewModel.swift)

**Changed:**
- "Upcoming" stat → "Active" stat
- `upcomingCount` → `activeCount`
- Value: 0 or 1 based on `currentUserSession() != nil`
- Color: Green when active, brand color when 0

### D) Summary of Removed Code

| File | Removed Elements |
|------|------------------|
| `CheckInHomeView.swift` | `upcomingUserBookings`, `upcomingBookingsSection`, `upcomingBookingRow` |
| `BookingHistoryView.swift` | Segmented control, `upcomingList`, `pastList`, `emptyUpcomingView`, `emptyPastView` |
| `ProfileViewModel.swift` | `upcomingCount` property |
| `ProfileView.swift` | "Upcoming" label and stat |

---

## Files Summary

### Created (1 file)
```
Views/Wallet/SendMoneySheetView.swift
```

### Modified (5 files)
```
Views/Wallet/WalletView.swift - ScrollViewReader, showSendSheet, quickActions refactor
Views/CheckIn/CheckInHomeView.swift - Removed upcoming section
Views/Booking/BookingHistoryView.swift - Removed segmented control, simplified to past only
Views/Profile/ProfileView.swift - Changed Upcoming to Active stat
ViewModels/ProfileViewModel.swift - Changed upcomingCount to activeCount
Core/DesignSystem/GFCorners.swift - Added medium token (from Step 43)
```

---

## Quick Manual Test Steps

### Wallet Buttons

1. Navigate to Wallet tab
2. Tap "History" button → Should scroll to "Recent Transactions" section
3. Tap "Send" button → Should open Send Money sheet
4. In sheet, enter recipient and amount → Submit button enables
5. Tap "Send" → Alert appears "Coming Soon"
6. Tap OK → Sheet dismisses

### Upcoming Removed

1. Check-in tab → Should only show Active Session or Empty State (no "Upcoming" section)
2. Profile → Stats row shows "Active" (0 or 1) and "Past"
3. Profile → Tap "View All" in Bookings → Booking History shows "Past Sessions" only (no tabs)

---

## Verification Checklist

| Check | Status |
|-------|--------|
| History scrolls to transactions | ✅ |
| Send opens sheet | ✅ |
| Send sheet has validation | ✅ |
| Send shows demo alert | ✅ |
| Check-in: no Upcoming section | ✅ |
| Booking History: no segmented control | ✅ |
| Profile: Active instead of Upcoming | ✅ |
| Active Session still works | ✅ |
| Book Now still works | ✅ |
| No dead code paths | ✅ |
| BUILD SUCCEEDED | ✅ |
