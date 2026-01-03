# BUGFIX — Total Paid Should Include Extension Fees

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Problem

Extending time correctly deducted wallet balance and increased session time, but the UI still displayed only the initial booking price. The "Total Paid" should reflect:

**Total Paid = Initial Booking Debit + All Extension Debits**

---

## Solution

Implemented stable booking linkage in wallet transactions so that all payments (initial + extensions) can be summed for a single booking.

---

## Files Modified (4)

| File | Changes |
|------|---------|
| `Services/WalletStore.swift` | Added optional overrides + `totalPaidCents()` helper |
| `Core/Services/Mock/MockBookingService.swift` | Updated initial booking debit with `bookingIdOverride` |
| `Views/CheckIn/CheckInHomeView.swift` | Updated extension debit + Total display |
| `Views/Dashboard/DashboardView.swift` | Updated Recent Activity price display |

---

## PART A — Stable Booking Linkage in WalletStore

### Updated `applyDebitForBooking` Signature

```swift
func applyDebitForBooking(
    amountCents: Int,
    bookingRef: String,
    gymName: String,
    gymId: String? = nil,
    bookingIdOverride: String? = nil,          // NEW
    paymentTransactionIdOverride: String? = nil // NEW
) throws -> WalletTransaction
```

### Transaction Creation

```swift
let stableBookingId = bookingIdOverride ?? "booking_\(bookingRef)"
let txRef = paymentTransactionIdOverride ?? bookingRef

// Used in WalletTransaction:
bookingId: stableBookingId,
paymentTransactionId: txRef,
```

This preserves backward compatibility while allowing real booking ID linkage.

---

## PART B — Updated Call Sites

### Initial Booking (MockBookingService)

```swift
try walletStore.applyDebitForBooking(
    amountCents: bookingCostCents,
    bookingRef: bookingRef,
    gymName: gymName,
    gymId: gymId,
    bookingIdOverride: bookingId,           // Links to booking_GF-XXXXXX
    paymentTransactionIdOverride: bookingRef
)
```

### Extension (CheckInHomeView)

```swift
try walletStore.applyDebitForBooking(
    amountCents: costCents,
    bookingRef: extRef,
    gymName: booking.gymName ?? "Gym",
    gymId: booking.gymId,
    bookingIdOverride: booking.id,          // Same booking ID as initial
    paymentTransactionIdOverride: extRef    // Unique per extension
)
```

---

## PART C — totalPaidCents Helper

### Added to WalletStore

```swift
func totalPaidCents(for bookingId: String) -> Int {
    let relatedPayments = transactions.filter { tx in
        tx.type == .payment &&
        tx.bookingId == bookingId &&
        tx.status == .completed
    }
    
    let totalCents = relatedPayments.reduce(0) { total, tx in
        total + Int((tx.amount * 100.0).rounded())
    }
    
    return max(0, totalCents)
}
```

This sums all completed payment transactions for a booking (initial + all extensions).

---

## PART D — Home Recent Activity Display

### Updated `formattedPrice` in RecentActivityCard

```swift
private var formattedPrice: String {
    // Show total paid from wallet (initial + extensions)
    let paidCents = WalletStore.shared.totalPaidCents(for: booking.id)
    if paidCents > 0 {
        return PricingCalculator.formatCentsAsEUR(paidCents)
    }
    
    // Fallback to booking.totalPrice or calculated price
    if booking.totalPrice > 0 {
        return String(format: "€%.2f", booking.totalPrice)
    }
    let totalCents = PricingCalculator.priceForBooking(...)
    return PricingCalculator.formatCentsAsEUR(totalCents)
}
```

---

## PART E — Check-in Booking Info Display

### Updated `bookingDetailsCard` Total

```swift
let paidCents = WalletStore.shared.totalPaidCents(for: booking.id)
if paidCents > 0 {
    Text(PricingCalculator.formatCentsAsEUR(paidCents))
} else {
    Text(String(format: "€%.2f", booking.totalPrice))
}
```

---

## Transaction Linkage Example

| Action | bookingId | paymentTransactionId | Amount |
|--------|-----------|---------------------|--------|
| Initial Book | `booking_GF-ABC123` | `GF-ABC123` | €10.00 |
| Extend +30m | `booking_GF-ABC123` | `booking_GF-ABC123-ext-30-1234567890` | €5.00 |
| Extend +60m | `booking_GF-ABC123` | `booking_GF-ABC123-ext-60-1234567891` | €10.00 |

**Total Paid:** €25.00 ✅

---

## Verification Checklist

| Check | Status |
|-------|--------|
| WalletStore signature backward compatible | ✅ |
| Initial booking links with bookingId | ✅ |
| Extensions link to same bookingId | ✅ |
| totalPaidCents sums all payments | ✅ |
| Recent Activity shows correct total | ✅ |
| Check-in details shows correct total | ✅ |
| Multi-extend still works | ✅ |
| Wallet deduction still works | ✅ |
| Booking duration/endTime still works | ✅ |
| BUILD SUCCEEDED | ✅ |

---

## Manual Test Steps

1. **Book a gym** (e.g., €10/hr for 60 min)
   - Recent Activity shows €10.00 ✅
   - Check-in Total shows €10.00 ✅

2. **Extend +30 min** (€5.00)
   - Balance decreases €5.00 ✅
   - End time extends +30 ✅
   - Recent Activity total → €15.00 ✅
   - Check-in total → €15.00 ✅

3. **Extend +60 min** (€10.00)
   - Totals → €25.00 ✅

4. **No errors on multi-extend** ✅
