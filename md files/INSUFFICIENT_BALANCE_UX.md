# UX IMPROVEMENT — Insufficient Balance UX (Booking + Extend Time)

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

Implemented clear insufficient balance handling for both booking and extend time flows:
- Pre-checks wallet balance before attempting action
- Shows informative alert with required vs available amounts
- Provides direct "Top Up Wallet" recovery action
- No partial bookings or extensions created on failure

---

## Files Modified (4)

| File | Changes |
|------|---------|
| `Views/CheckIn/CheckInHomeView.swift` | Added insufficient balance alert for Extend Time |
| `Views/Dashboard/DashboardView.swift` | Added insufficient balance alert for Quick Book |
| `Views/GymDetail/GymDetailView.swift` | Added insufficient balance alert for Book Now |
| `Core/Mock/MockBookingStore.swift` | Added `isSessionCancelled()` helper (from previous fix) |

---

## Alert Content

### Title
```
Insufficient Balance
```

### Message
```
You don't have enough balance to complete this action.

Required: €X.XX
Available: €Y.YY
```

### Actions
- **Top Up Wallet** → Navigates to Wallet (pushWallet)
- **Cancel** → Dismisses alert, no side effects

---

## Implementation Details

### 1. CheckInHomeView (Extend Time)

**State Variables Added:**
```swift
@State private var showInsufficientBalanceAlert = false
@State private var insufficientBalanceRequired: Int = 0  // cents
@State private var insufficientBalanceAvailable: Int = 0 // cents
```

**Balance Check (before debit):**
```swift
let walletStore = WalletStore.shared
let availableBalance = walletStore.balanceCents

if availableBalance < costCents {
    insufficientBalanceRequired = costCents
    insufficientBalanceAvailable = availableBalance
    showInsufficientBalanceAlert = true
    return  // Stop here - no debit attempted
}
```

### 2. DashboardView (Quick Book)

Same pattern with balance pre-check using:
```swift
let costCents = PricingCalculator.priceForBooking(
    durationMinutes: duration,
    gymPricePerHour: lastBooking.pricePerHour
)
```

### 3. GymDetailView (Book Now)

Added `attemptBooking(gym:duration:)` helper that:
1. Calculates cost using PricingCalculator
2. Checks wallet balance
3. Shows alert if insufficient
4. Otherwise proceeds with booking

---

## Behavior Rules ✅

| Rule | Status |
|------|--------|
| No partial booking created | ✅ |
| No time extended | ✅ |
| No wallet deduction | ✅ |
| User can retry after top up | ✅ |
| Alert appears immediately on tap | ✅ |
| Only one alert per failed attempt | ✅ |
| No stacked alerts | ✅ |

---

## Visual Tone

- System alert style (neutral)
- No red alarms
- No success green
- Standard iOS alert presentation

---

## Navigation

**Top Up Wallet** button uses:
```swift
router.pushWallet()
```

This navigates to the Wallet screen where user can top up.

---

## Manual Test Steps

### Booking Test
1. Set wallet balance to €0 (or low)
2. Go to Gym Detail → Book Now → Select duration
3. Alert appears: "Insufficient Balance"
4. Tap "Top Up Wallet" → Wallet opens
5. Top up → Return → Book succeeds

### Extend Test
1. Have an active session
2. Set wallet balance below extension cost
3. Go to Check-in → Tap Extend (+30, +60, or +90)
4. Alert appears with required/available amounts
5. Tap "Top Up Wallet" → Wallet opens
6. Top up → Return → Extend succeeds

### Quick Book Test
1. Have a previous booking (Quick Book section visible)
2. Set wallet balance to €0
3. Tap 1h, 1.5h, or 2h Quick Book button
4. Alert appears with amounts
5. Recovery flow works

---

## Verification Checklist

| Check | Status |
|-------|--------|
| Extend Time: Alert shows on insufficient balance | ✅ |
| Quick Book: Alert shows on insufficient balance | ✅ |
| Gym Detail Book: Alert shows on insufficient balance | ✅ |
| Required/Available amounts shown | ✅ |
| "Top Up Wallet" navigates to wallet | ✅ |
| "Cancel" dismisses alert | ✅ |
| No partial actions on failure | ✅ |
| No crashes | ✅ |
| No duplicate charges | ✅ |
| BUILD SUCCEEDED | ✅ |
