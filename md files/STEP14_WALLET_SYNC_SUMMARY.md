# STEP 14: Wallet Synchronization & Persistence

**Date:** 2026-01-01  
**Status:** ✅ Complete

---

## Overview

Implemented a centralized, persisted `WalletStore` as the single source of truth for wallet balance and transactions. This ensures:
- Balance syncs across Home and Wallet screens in real-time
- Bookings automatically debit the wallet
- Balance persists across app relaunches
- Insufficient funds prevents booking creation

---

## Files Created

| File | Purpose |
|------|---------|
| `Core/Pricing/PricingCalculator.swift` | Centralized pricing logic for booking cost calculations |

---

## Files Modified

| File | Changes |
|------|---------|
| `Services/WalletStore.swift` | **Complete rewrite** - Persists to UserDefaults, holds balance + transactions, provides `applyTopUp()` and `applyDebitForBooking()` methods |
| `Core/Services/Mock/MockWalletService.swift` | **Complete rewrite** - Now reads/writes through `WalletStore.shared` instead of maintaining its own state |
| `Core/Services/Mock/MockBookingService.swift` | Added wallet debit on booking creation using `PricingCalculator` and `WalletStore` |
| `Core/Services/BookingServiceProtocol.swift` | Added `insufficientFunds` error case |
| `Views/Wallet/WalletView.swift` | Now observes `WalletStore.shared` directly for real-time balance and transactions display |

---

## Architecture: Single Source of Truth

```
                    WalletStore.shared (Singleton + UserDefaults Persistence)
                           ↑
      ┌────────────────────┼────────────────────┐
      │                    │                    │
 WalletButtonView    WalletFullView    MockBookingService
 (Home balance)     (Full wallet)      (Debit on booking)
      │                    │                    │
      └────────────────────┼────────────────────┘
                           ↓
                  MockWalletService (reads/writes WalletStore)
```

---

## WalletStore API

### Properties (Published)
```swift
@Published private(set) var balanceCents: Int      // Balance in cents
@Published private(set) var currency: String       // "EUR"
@Published private(set) var transactions: [WalletTransaction]

var balance: Double         // Balance as Double (e.g., 45.00)
var walletBalance: WalletBalance  // Struct for compatibility
var formattedBalance: String  // "€45.00"
```

### Methods
```swift
func load()              // Load from UserDefaults
func save()              // Save to UserDefaults

func applyTopUp(amountCents: Int, ref: String, method: PaymentMethod?) -> WalletTransaction
func applyDebitForBooking(amountCents: Int, bookingRef: String, gymName: String, gymId: String?) throws -> WalletTransaction
func applyRefund(amountCents: Int, bookingRef: String, gymName: String) -> WalletTransaction
func resetToDemoDefaults()  // Debug: reset to €45.00
```

---

## PricingCalculator API

```swift
struct PricingCalculator {
    static let defaultPricePerHourCents: Int = 200  // €2.00

    static func priceForBooking(durationMinutes: Int, pricePerHourCents: Int) -> Int
    static func priceForBooking(durationMinutes: Int, gymPricePerHour: Double) -> Int
    static func priceForBookingEUR(durationMinutes: Int, gymPricePerHour: Double) -> Double
    static func formatCentsAsEUR(_ cents: Int) -> String  // "€3.50"
}
```

---

## Booking Flow with Wallet Debit

```
1. User taps "Book Now"
2. MockBookingService.createBooking() called
3. Fetch gym details → get pricePerHour
4. PricingCalculator.priceForBooking() → bookingCostCents
5. Check WalletStore.shared.balanceCents >= bookingCostCents
   - If NO: throw BookingServiceError.insufficientFunds → Show error
   - If YES: continue
6. WalletStore.shared.applyDebitForBooking() → creates transaction, debits balance, saves
7. Create Booking object, store in MockBookingStore
8. Return BookingConfirmation
9. UI automatically updates (Home badge, Wallet screen) via @ObservedObject
```

---

## Persistence

### UserDefaults Key
```
"wallet_store_v1"
```

### Persisted Data Structure
```swift
struct PersistedWalletData: Codable {
    var balanceCents: Int
    var currency: String
    var transactions: [WalletTransaction]
}
```

### When Saved
- After every `applyTopUp()`
- After every `applyDebitForBooking()`
- After every `applyRefund()`
- After `resetToDemoDefaults()`

---

## Error Handling

### Insufficient Funds
```swift
// WalletStore
guard balanceCents >= amountCents else {
    throw WalletServiceError.insufficientFunds
}

// MockBookingService catches and rethrows
catch {
    throw BookingServiceError.insufficientFunds
}

// UI displays
"Insufficient wallet balance. Please top up your wallet."
```

---

## Console Logging

### Successful Booking
```
🎯 BOOKING FLOW: createBooking called gymId=gym_1 date=... duration=60
💰 BOOKING FLOW: Price calculation - 60min @ €3.00/h = €3.00
💰 BOOKING FLOW: Current wallet balance = €45.00
💰 WalletStore.applyDebitForBooking: -€3.00 for 'FitRoma Center' → €42.00
💰 BOOKING FLOW: Wallet debited - new balance = €42.00
📦 BOOKING FLOW: Booking created ref=GF-ABC123...
```

### Insufficient Funds
```
💰 BOOKING FLOW: Current wallet balance = €2.00
❌ WalletStore.applyDebitForBooking: Insufficient balance (have €2.00, need €3.00)
❌ BOOKING FLOW: Wallet debit failed - Insufficient funds in wallet
```

### Top-Up
```
💳 MockWalletService.topUp: +€10.00 → €52.00
💰 WalletStore.applyTopUp: +€10.00 → €52.00
💰 WalletStore.save: Saved balance=€52.00 transactions=4
```

---

## Default Demo Values

| Property | Value |
|----------|-------|
| Starting Balance | €45.00 (4500 cents) |
| Currency | EUR |
| Seed Transactions | 3 demo transactions |

---

## What Changed from Previous Implementation

| Before | After |
|--------|-------|
| `WalletStore.balance` was hardcoded €12.50 | `WalletStore.balanceCents` persisted to UserDefaults |
| `MockWalletService` maintained its own `mockTransactions` array | Uses `WalletStore.shared.transactions` |
| Booking did NOT debit wallet | Booking debits wallet via `WalletStore.applyDebitForBooking()` |
| Home and Wallet could show different balances | Both use same `WalletStore.shared` singleton |

---

## Screen Balance Sources

| Screen | Old Source | New Source |
|--------|------------|------------|
| `WalletButtonView` (Home header) | Hardcoded mock balance | `WalletStore.shared.balance` |
| `WalletFullView` (Wallet tab) | `WalletFullViewModel.balance` | `WalletStore.shared.balance` |

---

## Testing Checklist

| Test | Expected |
|------|----------|
| Launch app: Home balance shows €45.00 | ✅ Uses `WalletStore.shared.balance` |
| Open Wallet: same balance €45.00 | ✅ Same `WalletStore.shared.balance` |
| Book a 60-min session (€3/h gym) | ✅ Balance decreases by €3.00 immediately |
| New transaction appears in Wallet | ✅ "Booking at {GymName}" with negative amount |
| Kill app and relaunch | ✅ Balance remains at new value (persisted) |
| Try booking with insufficient balance | ✅ Error: "Insufficient wallet balance" |
| Top up €10.00 | ✅ Balance increases, new deposit transaction appears |

---

## Dependencies

- `WalletStore` is initialized as singleton on first access
- `MockWalletService` depends on `WalletStore.shared`
- `MockBookingService` depends on `WalletStore.shared` and `PricingCalculator`
- `WalletButtonView` observes `WalletStore.shared`
- `WalletFullView` observes `WalletStore.shared`

---

## Build Status

✅ **BUILD SUCCEEDED**
