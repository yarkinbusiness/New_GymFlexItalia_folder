# UX BUGFIX — History/Receipt Totals Should Include Extensions

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Problem

Receipt surfaces (Booking Detail, Transaction Detail, Booking History) showed only the initial booking price, not the true total paid including extensions.

---

## Solution

All receipt surfaces now use `WalletStore.totalPaidCents(for: booking.id)` as the source of truth for total paid.

---

## Files Modified (3)

| File | Changes |
|------|---------|
| `Views/Booking/BookingDetailView.swift` | Updated Total row + "Includes extensions" hint |
| `Views/Wallet/TransactionDetailView.swift` | Added "Booking Total Paid" row |
| `Views/Booking/BookingHistoryView.swift` | Updated row price display |

---

## PART B — BookingDetailView

### Total Row Updated

```swift
let paidCents = WalletStore.shared.totalPaidCents(for: booking.id)
let baseCents = Int((booking.totalPrice * 100).rounded())
let totalString = (paidCents > 0)
    ? PricingCalculator.formatCentsAsEUR(paidCents)
    : String(format: "€%.2f", booking.totalPrice)
let hasExtensions = paidCents > baseCents && baseCents > 0
```

### "Includes extensions" Hint

When `paidCents > baseCents`, a subtle hint is shown:

```
┌────────────────────────────────────┐
│ Total                      €25.00  │
│                 Includes extensions │ ← Only when extensions detected
└────────────────────────────────────┘
```

---

## PART C — TransactionDetailView

### New "Booking Total Paid" Row

For payment transactions linked to a booking:

```swift
if txn.type == .payment, let bookingId = txn.bookingId, !bookingId.isEmpty {
    let bookingTotalPaidCents = WalletStore.shared.totalPaidCents(for: bookingId)
    if bookingTotalPaidCents > 0 {
        TransactionDetailRow(
            label: "Booking Total Paid",
            value: PricingCalculator.formatCentsAsEUR(bookingTotalPaidCents),
            icon: "eurosign.circle.fill"
        )
    }
}
```

### Display Example

```
┌────────────────────────────────────┐
│ Description    Booking at FitLab   │
│ Reference      booking_GF-ABC-ext  │
│ Date           January 3, 2026     │
│ ...                                │
│ Balance Before           €50.00    │
│ Balance After            €45.00    │
│ Booking Total Paid       €25.00    │ ← NEW: Shows full booking total
└────────────────────────────────────┘
```

This allows users to see both:
- **This transaction:** €5.00 (extension amount)
- **Booking Total Paid:** €25.00 (initial + all extensions)

---

## PART D — BookingHistoryView

### Row Price Updated

```swift
private var formattedPrice: String {
    let paidCents = WalletStore.shared.totalPaidCents(for: booking.id)
    if paidCents > 0 {
        return PricingCalculator.formatCentsAsEUR(paidCents)
    }
    return String(format: "€%.2f", booking.totalPrice)
}
```

---

## Screens Now Using totalPaidCents

| Screen | Source of Truth |
|--------|-----------------|
| Home > Recent Activity | `WalletStore.shared.totalPaidCents(for: booking.id)` |
| Check-in > Booking Details | `WalletStore.shared.totalPaidCents(for: booking.id)` |
| Booking History rows | `WalletStore.shared.totalPaidCents(for: booking.id)` |
| Booking Detail (receipt) | `WalletStore.shared.totalPaidCents(for: booking.id)` |
| Transaction Detail | `WalletStore.shared.totalPaidCents(for: tx.bookingId)` |

---

## Verification Checklist

| Check | Status |
|-------|--------|
| BookingDetailView shows correct total | ✅ |
| BookingDetailView shows "Includes extensions" when applicable | ✅ |
| TransactionDetailView shows "Booking Total Paid" row | ✅ |
| BookingHistoryView rows show correct total | ✅ |
| Layouts unchanged | ✅ |
| Navigation unchanged | ✅ |
| BUILD SUCCEEDED | ✅ |

---

## Manual Test Steps

1. **Book €10/hr 60m**
2. **Extend +30 (€5), extend +60 (€10)** → total paid €25

3. **Verify:**
   - BookingDetailView shows Total: **€25.00** + "Includes extensions"
   - Wallet TransactionDetailView for extension tx shows:
     - Transaction Amount: €5.00 (the extension)
     - Booking Total Paid: **€25.00**
   - BookingHistoryView row shows: **€25.00**

4. **No regressions** to navigation or layout ✅
