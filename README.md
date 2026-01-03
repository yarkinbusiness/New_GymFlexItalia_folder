# GymFlex Italia

A production-grade iOS application for flexible, on-demand gym access with wallet-based session management.

---

## Project Overview

GymFlex Italia enables users to discover, book, and access gyms across Italy with a pay-per-session model. The app prioritizes financial correctness, UX clarity, and architectural scalability.

### Core Concept

- Users maintain a digital wallet balance
- Browse and book gym sessions by the hour
- Extend ongoing sessions in real-time
- All payments are handled through the wallet ledger
- No subscriptions, no hidden fees, no dark patterns

### Architecture Philosophy

The codebase is designed for long-term maintainability and future expansion:

- **User App** (current): End users discover gyms and manage sessions
- **Owner App** (planned): Gym owners validate check-ins and manage their facilities

### Guiding Principles

1. **Trust**: The wallet ledger is the immutable source of truth for all financial transactions
2. **Clarity**: Status labels, error messages, and flows are unambiguous
3. **Correctness**: Financial calculations are auditable and verifiable
4. **Scalability**: Architecture supports future backend integration without rewrites

---

## Core Features

### Gym Discovery

- **List View**: Cards with gym details, pricing, amenities, and distance
- **Map View**: Interactive map with gym pins
- **Filters**: Search by name, amenities, equipment, price range, workout types
- **Location-Based**: Nearby gyms sorted by distance when location is available

### Gym Detail & Booking

- Full gym information: photos, amenities, equipment, hours, contact
- Hour-based booking with real-time price calculation
- Immediate wallet debit upon booking confirmation
- Insufficient balance handling with prompt to top up

### Active Session Management

- Single active session enforced (no overlapping bookings)
- Live countdown timer during session
- **Extend Session**: Add time in 30-minute increments
- Extension payments deducted from wallet in real-time
- Session ends automatically when time expires

### Wallet System

- In-app balance management in EUR (stored as cents)
- Top-up via simulated payment flow
- Transaction history with full details
- Receipt-style transaction detail views

### Map Navigation

- Tap gym pin to view Route or Details
- Route button opens Apple Maps with driving directions
- Handles missing coordinates gracefully

### Groups & Chat

- Mock group system for workout partners
- Chat interface (UI complete, backend mocked)

### Profile & Settings

- User profile management
- Booking statistics (upcoming, past, cancelled)
- App preferences and configuration

---

## Architecture Overview

### Pattern: MVVM with Services

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                        │
│         (DashboardView, CheckInHomeView, WalletView, etc.)  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        ViewModels                           │
│     (HomeViewModel, BookingViewModel, WalletViewModel)      │
│              Owns view state, coordinates logic             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AppContainer (DI)                        │
│         Provides services via EnvironmentObject             │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   Services    │    │    Stores     │    │  Protocols    │
│ (MockGymSvc)  │    │ (WalletStore) │    │ (GymService)  │
│               │    │ (BookingStore)│    │               │
└───────────────┘    └───────────────┘    └───────────────┘
```

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| `AppContainer` for DI | Avoids scattered singletons; makes testing straightforward |
| Protocol-based services | Enables mock/real swapping; backend integration without UI changes |
| Stores as controlled singletons | `WalletStore` and `MockBookingStore` need global state for consistency |
| `@EnvironmentObject` for routing | `AppRouter` centralizes navigation state |
| SwiftUI-first | Modern approach with better state management than UIKit |

### Directory Structure

```
Gym Flex Italia/
├── Core/
│   ├── AppContainer.swift      # Dependency injection
│   ├── DesignSystem/           # Colors, fonts, spacing tokens
│   ├── Mock/                   # Mock data stores
│   ├── Navigation/             # AppRouter, routes
│   ├── Network/                # Network client (unused in mock mode)
│   ├── Services/               # Service protocols and implementations
│   └── ...
├── Models/
│   ├── Gym.swift
│   ├── Booking.swift
│   ├── WalletTransaction.swift
│   └── ...
├── Services/
│   ├── WalletStore.swift       # Single source of truth for wallet
│   ├── LocationService.swift
│   └── ...
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── BookingViewModel.swift
│   └── ...
└── Views/
    ├── Dashboard/
    ├── CheckIn/
    ├── Wallet/
    ├── Discovery/
    └── ...
```

---

## Wallet & Ledger Design

The wallet system is designed with financial correctness as the primary goal.

### Core Invariants

1. **Balance-Transaction Consistency**: `balanceCents` always equals the computed sum of all completed transactions
2. **Immutable Ledger**: Transactions are append-only; never modified or deleted
3. **No Refunds**: Booking cancellation does not create refund transactions (business policy)
4. **No Negative Balance**: Payments are rejected if they would result in negative balance
5. **Idempotent Transactions**: Duplicate charges are prevented via transaction ID checks

### WalletStore as Source of Truth

```swift
final class WalletStore: ObservableObject {
    @Published private(set) var balanceCents: Int      // Current balance
    @Published private(set) var transactions: [WalletTransaction]  // Ledger
    
    // All mutations go through these methods:
    func applyTopUp(amountCents:paymentMethod:) -> WalletTransaction
    func applyDebitForBooking(amountCents:bookingRef:gymName:...) throws -> WalletTransaction
}
```

### Transaction Types

| Type | Effect on Balance | Use Case |
|------|-------------------|----------|
| `.deposit` | +amountCents | Wallet top-up |
| `.payment` | -amountCents | Booking payment, session extension |
| `.refund` | +amountCents | (Not used; no-refund policy) |

### Booking Payment Flow

```
User Confirms Booking
        ↓
BookingService.createBooking()
        ↓
WalletStore.applyDebitForBooking()
    ├─ Check balance ≥ amount
    ├─ Create WalletTransaction(type: .payment, bookingId: stable_id)
    ├─ Append to transactions
    ├─ Update balanceCents
    └─ Validate ledger integrity (DEBUG)
        ↓
Booking Created with paymentTransactionId
```

### Session Extensions

- Extensions link to the same `bookingId` as the original payment
- Each extension creates a new `WalletTransaction` with unique `paymentTransactionId`
- `totalPaidCents(for: bookingId)` sums all `.payment` transactions for that booking

### Ledger Integrity Validation (DEBUG)

In debug builds, `validateLedgerIntegrity()` runs after every mutation:

- Verifies `balanceCents == computedBalanceCents`
- Checks for duplicate transaction IDs
- Triggers `assertionFailure` if invariants are violated

### Self-Healing Migration

For persisted data from older versions:

- On init, checks if stored `balanceCents` matches computed ledger total
- If mismatch and migration flag not set: auto-heals by syncing balance
- If mismatch persists after migration: indicates real bug, logs warning

---

## Booking & Session Lifecycle

### Booking States

| Status | Description |
|--------|-------------|
| `.booked` | Future session, not yet started |
| `.ongoing` | Current time is within booking window |
| `.completed` | Session time has ended |
| `.cancelled` | User cancelled before session started |

### State Transitions

```
    ┌─────────────┐
    │   BOOKED    │───────────────┐
    └──────┬──────┘               │
           │ (start time reached) │ (user cancels)
           ▼                      ▼
    ┌─────────────┐         ┌───────────┐
    │   ONGOING   │         │ CANCELLED │
    └──────┬──────┘         └───────────┘
           │ (end time reached)
           ▼
    ┌─────────────┐
    │  COMPLETED  │
    └─────────────┘
```

### Session Rules

1. **Single Active Session**: Users can have only one ongoing booking at a time
2. **No Manual Check-In**: Session starts automatically when booking time begins
3. **Extensions**: Only allowed during `.ongoing` state
4. **Cancellation**: Only allowed before session starts; no refund issued

### Extension Logic

```swift
func extendSession(minutesToAdd: Int) {
    guard booking.isOngoing else { return }
    
    let extensionCostCents = calculateCost(minutes: minutesToAdd)
    
    // Debit wallet with same bookingId
    let tx = WalletStore.applyDebitForBooking(
        amountCents: extensionCostCents,
        bookingIdOverride: booking.id,  // Links to original
        paymentTransactionIdOverride: UUID().uuidString  // Unique tx
    )
    
    booking.endTime += TimeInterval(minutesToAdd * 60)
}
```

---

## Location Handling

### Permission Flow

```
App Launch
    ↓
Check authorizationStatus
    ├─ .notDetermined → Show "Enable Location" banner
    ├─ .denied/.restricted → Show "Open Settings" banner
    └─ .authorizedWhenInUse/.authorizedAlways → Start location updates
```

### Resilient Location Acquisition

The app handles edge cases where location permission is granted but no fix is obtained:

1. **"Ask Next Time / When I Share"**: iOS may grant one-time access without continuous updates
2. **Simulator without location**: Returns `.locationUnknown` error

The `ensureFreshLocation(reason:)` method:

- Requests location and waits up to 2 seconds
- Retries once if no fix received
- Sets `locationIssue = .authorizedButNoFix` if still no location
- Shows user guidance: "Please set Location to 'While Using the App' in Settings"

### Location States

| `LocationIssue` | User Guidance | Button |
|-----------------|---------------|--------|
| `.notDetermined` | "Enable location to see nearby gyms" | Enable Location |
| `.deniedOrRestricted` | "Location access denied" | Open Settings |
| `.authorizedButNoFix` | "Can't get location fix" | Open Settings + Retry |
| `nil` | (No banner shown) | - |

### Simulator Notes

- Simulator must have a location configured: Features > Location > Custom Location
- Without location, gyms display without distance information
- The app gracefully shows first 3 gyms when location unavailable

---

## UX Decisions & Principles

### Status Clarity

- **"Ongoing"** vs **"Session Ended"**: Clear distinction prevents confusion
- No ambiguous states like "In Progress" or "Active"
- Timestamps shown for all bookings

### No Manual Check-In

- Sessions start automatically based on booking time
- Reduces friction and potential for user error
- Gym owner app (future) handles verification separately

### Immediate Feedback

- Wallet balance updates instantly after booking/extension
- Success confirmations are explicit
- Error states clearly explain what happened and next steps

### Financial Transparency

- All receipts show itemized costs
- Transaction history accessible from wallet
- "Includes extensions" hint when total differs from base price

### Consistent Microcopy

- Button labels are action-oriented: "Book Now", "Extend Session", "Top Up"
- Error messages explain both the problem and solution
- No jargon or technical terms exposed to users

### Apple Human Interface Alignment

- Standard navigation patterns
- System colors for semantic meaning
- Native sheet presentations and modals

---

## What Is Mocked vs Real

### Currently Mocked

| Component | Location | Notes |
|-----------|----------|-------|
| Gym catalog | `MockDataStore.gyms` | 4 sample gyms with full data |
| Gym service | `MockGymService` | Returns mock gym data |
| Booking service | `MockBookingService` | Creates/manages bookings in memory |
| Booking store | `MockBookingStore` | Persists bookings to UserDefaults |
| Wallet service | `MockWalletService` | Full wallet functionality, persisted |
| Groups/Chat | `MockGroupService` | Chat UI functional, messages in memory |
| Auth | `MockAuthService` | Auto-approves login |
| User profile | `MockUserService` | Static user data |

### Real Implementations

| Component | Location | Notes |
|-----------|----------|-------|
| Location | `LocationService` | Real CLLocationManager integration |
| Wallet persistence | `WalletStore` | UserDefaults-backed, production-ready logic |
| Apple Maps routing | `GymDiscoveryView` | Opens real Maps app |

### Backend Integration Path

All services are protocol-based. To integrate a real backend:

1. Implement `GymServiceProtocol`, `BookingServiceProtocol`, etc.
2. Swap implementations in `AppContainer`
3. No view or ViewModel changes required

---

## Future Roadmap

### Near Term

- **Gym Owner App**: QR code scanning, session validation, check-in approval
- **Backend Integration**: REST/GraphQL services replacing mock implementations
- **Push Notifications**: Session reminders, booking confirmations

### Medium Term

- **Reservation System v2**: Multi-day bookings, recurring sessions
- **Payment Integration**: Stripe/Apple Pay for real transactions
- **Analytics**: Usage tracking, business metrics

### Long Term

- **Accessibility Pass**: Full VoiceOver support, Dynamic Type
- **Performance Optimization**: Image caching, lazy loading
- **Localization**: Multi-language support

---

## How to Run the App

### Requirements

- **Xcode**: 26.1 or later
- **iOS Target**: iOS 26.1+
- **macOS**: Tahoe (26.0) or later for building

### Running on Simulator

1. Open `Gym Flex Italia.xcodeproj`
2. Select iPhone 17 Pro simulator (or any iOS 26+ simulator)
3. **Important**: Set simulator location: Features > Location > Custom Location
4. Build and Run (Cmd+R)

### Resetting Permissions

If location permission is stuck:

```bash
# Reset all simulator privacy settings
xcrun simctl privacy booted reset all

# Or erase simulator entirely
xcrun simctl erase booted
```

Then delete the app and reinstall.

### Running on Device

1. Configure signing in project settings
2. Enable Developer Mode on device
3. Build and deploy via Xcode

---

## Development Notes

### Debug Assertions

DEBUG builds include assertions for:

- Wallet ledger integrity after every mutation
- Transaction duplicate prevention
- Balance consistency checks

These assertions do NOT run in Release builds.

### Ledger Migration

On first launch after certain updates, the app may auto-heal wallet ledger mismatches:

- Logs: `📍 WalletStore: Migrating ledger...`
- Sets `wallet_ledger_migrated_v1` flag in UserDefaults
- Safe for production; only runs once

### Clean Rebuild

If experiencing build issues:

1. Clean build folder: Cmd+Shift+K
2. Delete derived data: `~/Library/Developer/Xcode/DerivedData`
3. Reset package caches if using SPM

### Console Logging

DEBUG builds emit detailed logs:

- Location: `📍 LocationService...`
- Wallet: `💰 WalletStore...`
- Booking: `📅 BookingStore...`
- Navigation: `🔀 AppRouter...`

---

## Contribution Guidelines

### Architecture Rules

1. **Use AppContainer**: All services injected via container, not instantiated directly
2. **One-way data flow**: Views observe ViewModels; ViewModels call services
3. **Protocol-first services**: New services must have protocol definitions

### Wallet/Ledger Rules

1. **Never modify transactions directly**: Always use `WalletStore` methods
2. **Preserve immutability**: Transactions are append-only
3. **Maintain invariants**: Balance must equal computed sum

### Code Style

1. Follow existing patterns and naming conventions
2. Use design system tokens (`AppColors`, `AppFonts`, `Spacing`)
3. Document non-obvious logic with comments
4. Add DEBUG logging for significant state changes

### Testing

1. Reset simulator state before testing permission flows
2. Verify wallet ledger assertions pass in DEBUG builds
3. Test both list and map views in Discovery

---

## License

Proprietary. All rights reserved.

---

## Contact

For questions about this codebase, contact the development team.
