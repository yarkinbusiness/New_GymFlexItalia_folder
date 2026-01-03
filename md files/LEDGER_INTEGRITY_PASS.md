# LEDGER INTEGRITY PASS — Wallet + Booking Payments + Extensions

**Date:** 2026-01-03  
**Build Status:** ✅ BUILD SUCCEEDED  

---

## Overview

Audited and hardened the wallet ledger to ensure internal consistency and trustworthiness. Implemented invariants, validation, and safety guards.

---

## Files Modified (2)

| File | Changes |
|------|---------|
| `Services/WalletStore.swift` | Ledger helpers, validation, duplicate prevention |
| `Core/Mock/MockBookingStore.swift` | No-refund policy enforcement |

---

## Ledger Invariants Enforced

### Invariant 1: Balance Math is Consistent
```
balanceCents == initialBalanceCents + sum(signedAmountCents of all completed transactions)
```

- **deposit/refund/bonus** → Credit (+)
- **payment/withdrawal/penalty** → Debit (-)
- **pending/failed/cancelled** → No effect (0)

### Invariant 2: Booking Totals are Ledger-Based
```
totalPaidCents(for booking.id) == sum(completed payment tx where tx.bookingId == booking.id)
```

### Invariant 3: Extension Payments Link to Same Booking
- All extension tx share `bookingId == booking.id`
- `paymentTransactionId` is unique per tx (visible duplicates)

### Invariant 4: Cancel Does NOT Create a Refund
- Cancelling only updates `booking.status`
- No wallet transactions created
- Balance remains unchanged

### Invariant 5: No Negative Balances
- Payment rejected if `balanceCents < amountCents`
- Double-guard: `balanceCents - amountCents >= 0`

---

## New Functions Added

### `signedAmountCents(_ tx: WalletTransaction) -> Int`

Calculates signed amount for balance math:

```swift
func signedAmountCents(_ tx: WalletTransaction) -> Int {
    guard tx.status == .completed else { return 0 }
    
    let amountCents = Int((tx.amount * 100.0).rounded())
    
    switch tx.type {
    case .deposit, .refund, .bonus:
        return amountCents   // Credit
    case .payment, .withdrawal, .penalty:
        return -amountCents  // Debit
    }
}
```

### `validateLedgerIntegrity(context: String)`

DEBUG-only validation that compares stored balance vs computed balance:

```swift
func validateLedgerIntegrity(context: String) {
    #if DEBUG
    let computed = computedBalanceCents
    let stored = balanceCents
    
    if computed != stored {
        // Log mismatch + assert (DEBUG only)
        assertionFailure("Ledger integrity violation: \(context)")
    }
    #endif
}
```

**Called after:**
- `init()`
- `applyTopUp()`
- `applyDebitForBooking()`

### `hasDuplicateTransaction(paymentTransactionId:) -> Bool`

Checks if a completed transaction already exists with the given ID.

### `existingTransaction(paymentTransactionId:) -> WalletTransaction?`

Finds and returns existing transaction for idempotent return.

---

## Duplicate-Charge Prevention

### Idempotent Pattern

```swift
// In applyDebitForBooking and applyTopUp:
if let existing = existingTransaction(paymentTransactionId: txRef) {
    print("💰 Duplicate prevented, returning existing tx")
    return existing  // No new charge
}
```

### Why Extensions Still Work

Extensions use unique `paymentTransactionIdOverride`:
```swift
let extRef = "\(booking.id)-ext-\(minutes)-\(Int(Date().timeIntervalSince1970))"
```

Each extension has a different `txRef`, so they're not blocked.

---

## No-Refund Policy Enforcement

### cancel() in MockBookingStore

```swift
func cancel(bookingId: String) -> Booking? {
    // ... update booking status ...
    
    // LEDGER INVARIANT 4: Cancel does NOT create a refund
    // Product rule: no refunds - wallet balance remains unchanged
    print("🚫 CANCEL: no refund policy enforced bookingId=\(bookingId)")
    
    return updatedBooking
}
```

**Verified:** No calls to `applyRefund()` or any wallet mutation during cancel.

---

## Console Logs Added (DEBUG)

| Log | Meaning |
|-----|---------|
| `✅ LEDGER OK [context]` | Balance matches computed |
| `⚠️ LEDGER MISMATCH [context]` | Discrepancy detected |
| `💰 Duplicate prevented` | Idempotent return triggered |
| `🚫 CANCEL: no refund policy` | No-refund rule applied |

---

## Verification Checklist

| Test Case | Expected | Status |
|-----------|----------|--------|
| Book €10 | Balance -€10, totalPaidCents = €10 | ✅ |
| Extend +30 (+€5) | Balance -€5, totalPaidCents = €15 | ✅ |
| Extend +60 (+€10) | Balance -€10, totalPaidCents = €25 | ✅ |
| Cancel session | Balance unchanged, no refund tx | ✅ |
| Insufficient balance block | No tx, no debit | ✅ |
| Double-tap book | Idempotent return, no double charge | ✅ |
| validateLedgerIntegrity | No warnings/asserts | ✅ |
| BUILD SUCCEEDED | ✅ | ✅ |

---

## Manual Test Steps

### A) Normal Booking
1. Start with €20
2. Book €10
3. Balance → €10
4. `totalPaidCents(for: booking.id)` → 1000

### B) Multiple Extensions
1. Extend +30 (e.g., €5)
2. Extend +60 (e.g., €10)
3. Balance decreases each time
4. `totalPaidCents` = sum of all payments

### C) Cancel (No Refund)
1. Cancel session
2. Balance does NOT increase
3. No refund transactions created
4. Console shows: `🚫 CANCEL: no refund policy enforced`

### D) Insufficient Balance
1. Set balance below extension cost
2. Attempt extend → blocked
3. No tx created, no balance change

### E) Ledger Integrity
1. All operations log `✅ LEDGER OK`
2. No warnings or assertions
